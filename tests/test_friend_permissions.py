from types import SimpleNamespace as NS

import pytest

from app.agent.actions import ActionVerificationError, VerifiedActions
from app.agent.contracts import TaskItem, TaskOptions, TaskRequest
from app.agent.native_driver import NativeWeixinDriver
from app.agent.profile import get_weixin_profile
from app.agent.retry import AutomationRetryError, WeixinUnresponsiveError
from app.agent.runtime import TaskControl
from app.agent.waiters import ActionDeadlineExceeded, action_deadline
from app.agent.workflows import WeixinWorkflowEngine
from tests.test_agent_workflows import FakeDriver


class ImmediateWaiter:
    def wait(self, predicate, *args, **kwargs):
        return bool(predicate())


def test_pattern_only_selection_has_no_mouse_or_keyboard_fallback():
    calls = []
    actions = VerifiedActions(
        waiter=ImmediateWaiter(),
        click_fallback=lambda *_: calls.append("click"),
        replace_text_fallback=lambda *_: calls.append("keyboard"),
    )
    control = NS(GetSelectionItemPattern=lambda: None)
    with pytest.raises(ActionVerificationError):
        actions.select(control, lambda: False, allow_click_fallback=False)
    assert calls == []


@pytest.mark.parametrize("failure", ["false", "exception", "unverified"])
def test_pattern_only_selection_does_not_replay_failed_select(failure):
    calls = []

    def select(**kwargs):
        calls.append("select")
        if failure == "exception":
            raise RuntimeError("provider failure")
        return failure != "false"

    actions = VerifiedActions(
        waiter=ImmediateWaiter(),
        click_fallback=lambda *_: calls.append("click"),
        replace_text_fallback=lambda *_: calls.append("keyboard"),
    )
    with pytest.raises(ActionVerificationError):
        actions.select(
            NS(GetSelectionItemPattern=lambda: NS(Select=select)),
            lambda: False,
            allow_click_fallback=False,
        )
    assert calls == ["select"]


def test_pattern_only_selection_never_replays_internal_type_error():
    calls = []

    def select(**kwargs):
        calls.append(kwargs)
        if len(calls) == 1:
            raise TypeError("internal provider failure, not a signature mismatch")
        return True

    actions = VerifiedActions(
        waiter=ImmediateWaiter(), click_fallback=lambda *_: calls.append("click"),
        replace_text_fallback=lambda *_: calls.append("keyboard"),
    )
    with pytest.raises(ActionVerificationError):
        actions.select(NS(GetSelectionItemPattern=lambda: NS(Select=select)),
                       lambda: True, allow_click_fallback=False)
    assert calls == [{"waitTime": 0}]


def test_pattern_only_selection_supports_no_argument_signature_without_replay():
    calls = []

    def select():
        calls.append("select")
        return True

    actions = VerifiedActions(
        waiter=ImmediateWaiter(), click_fallback=lambda *_: calls.append("click"),
        replace_text_fallback=lambda *_: calls.append("keyboard"),
    )
    result = actions.select(NS(GetSelectionItemPattern=lambda: NS(Select=select)),
                            lambda: True, allow_click_fallback=False)
    assert result.verified is True
    assert calls == ["select"]


@pytest.fixture
def permission_form(monkeypatch):
    state = {"朋友圈": False, "仅聊天": False}
    calls = []
    profile = get_weixin_profile("4.1.13.65")
    root = NS(
        Name="申请添加朋友", ControlTypeName="WindowControl",
        ClassName=profile.verify_friend_root_class, NativeWindowHandle=303,
        ProcessId=202, IsEnabled=True, IsOffscreen=False,
        GetRuntimeId=lambda: (202, 303),
    )
    group = NS(GetRuntimeId=lambda: (202, 303, 10))

    class ChoicePattern:
        SelectionContainer = group

        def __init__(self, label):
            self.label = label

        @property
        def IsSelected(self):
            return state[self.label]

        def Select(self, **kwargs):
            calls.append(("select", self.label))
            state.update({label: label == self.label for label in state})
            return True

    def choice(label, *, pattern=True, control_type="RadioButtonControl"):
        return NS(
            Name=label, ControlTypeName=control_type,
            IsEnabled=True, IsOffscreen=False,
            GetRuntimeId=lambda: (202, 303, 11 if label == "朋友圈" else 12),
            GetParentControl=lambda: group,
            GetSelectionItemPattern=lambda: ChoicePattern(label) if pattern else None,
        )

    def edit(name, text):
        value = NS(Value=text, IsReadOnly=False)
        value.SetValue = lambda new, **kwargs: setattr(value, "Value", new) or True
        return NS(Name=name, ControlTypeName="EditControl", IsEnabled=True,
                  IsOffscreen=False, GetValuePattern=lambda: value)

    greeting = edit("发送添加朋友申请", "original greeting")
    remark = edit("修改备注", "original remark")
    prompt = NS(Name="你的联系人太多，添加新的朋友时需选择权限 必填",
                ControlTypeName="TextControl", IsEnabled=True, IsOffscreen=False)
    controls = [prompt, choice("朋友圈"), choice("仅聊天"), greeting, remark]
    query_count = [0]

    def query(**selector):
        assert selector["hwnd"] == 303
        if "root" in selector:
            assert selector["root"] is root
        query_count[0] += 1
        return [c for c in list(controls) if (
            (not selector.get("control_type") or c.ControlTypeName == selector["control_type"])
            and (not selector.get("control_types") or c.ControlTypeName in selector["control_types"])
            and (not selector.get("name") or c.Name == selector["name"])
            and (not selector.get("visible") or not c.IsOffscreen)
            and (not selector.get("enabled", True) or c.IsEnabled)
        )]

    driver = NativeWeixinDriver(gate_backend=object())
    driver._session = NS(hwnd=101, pid=202, profile=profile)
    driver._verify_hwnd = 303
    driver._query = NS()
    driver._uia = NS(ControlFromHandle=lambda hwnd: root)
    driver._find_scoped_controls = query
    driver._raise_scoped_risk = lambda **kwargs: None
    driver.ensure_window_responsive = lambda *args: True
    driver._actions = VerifiedActions(
        waiter=ImmediateWaiter(),
        click_fallback=lambda *_: calls.append("click"),
        replace_text_fallback=lambda *_: calls.append("keyboard"),
    )
    monkeypatch.setattr(driver, "_walk", lambda *_: pytest.fail("no tree walk"))
    monkeypatch.setattr(driver, "_all_nodes", lambda *_: pytest.fail("no global query"))
    return NS(driver=driver, state=state, calls=calls, controls=controls,
              root=root, choice=choice, group=group, query=query,
              query_count=query_count)


def test_missing_permission_region_keeps_normal_form_unchanged(permission_form):
    form = permission_form
    form.controls[:] = [c for c in form.controls if c.ControlTypeName == "EditControl"]
    fields = form.driver.set_friend_fields("hello", "remark")
    assert fields == {"greeting": "hello", "remark": "remark"}
    assert form.calls == []


def test_unselected_permission_selects_moments_and_reads_back(permission_form):
    form = permission_form
    fields = form.driver.set_friend_fields("hello", "remark")
    assert fields == {"greeting": "hello", "remark": "remark"}
    assert form.state == {"朋友圈": True, "仅聊天": False}
    assert form.calls == [("select", "朋友圈")]
    assert form.query_count[0] <= 6


@pytest.mark.parametrize("selected", ["朋友圈", "仅聊天"])
def test_existing_valid_permission_is_preserved(permission_form, selected):
    form = permission_form
    form.state[selected] = True
    form.driver.set_friend_fields(None, "")
    assert form.state[selected] is True
    assert form.calls == []


@pytest.mark.parametrize("variant", [
    "prompt_only", "one_option", "duplicate", "no_pattern", "text_only",
    "different_groups", "both_selected", "disabled", "too_many", "duplicate_unsupported",
])
def test_unverifiable_permission_fails_closed(permission_form, variant):
    form = permission_form
    if variant == "prompt_only":
        form.controls[:] = [c for c in form.controls if c.ControlTypeName != "RadioButtonControl"]
    elif variant == "one_option":
        form.controls.pop(2)
    elif variant == "duplicate":
        form.controls.append(form.choice("朋友圈"))
    elif variant == "no_pattern":
        form.controls[1] = form.choice("朋友圈", pattern=False)
    elif variant == "text_only":
        form.controls[1] = form.choice("朋友圈", control_type="TextControl")
    elif variant == "different_groups":
        pattern = form.controls[2].GetSelectionItemPattern()
        pattern.SelectionContainer = NS(GetRuntimeId=lambda: (999, 10))
        form.controls[2].GetSelectionItemPattern = lambda: pattern
    elif variant == "both_selected":
        form.state.update({"朋友圈": True, "仅聊天": True})
    elif variant == "disabled":
        form.controls[1].IsEnabled = False
    elif variant == "too_many":
        form.controls.extend(NS(Name="label", ControlTypeName="TextControl",
                                IsEnabled=True, IsOffscreen=False) for _ in range(129))
    elif variant == "duplicate_unsupported":
        form.controls.append(form.choice("朋友圈", control_type="CheckBoxControl"))
    with pytest.raises(AutomationRetryError) as raised:
        form.driver.set_friend_fields(None, "")
    assert raised.value.code == "FRIEND_PERMISSION_UNVERIFIED"
    assert raised.value.recoverable is False
    assert form.calls == []


def test_choice_is_relocated_before_selecting_stale_observation(permission_form):
    form = permission_form
    stale = form.controls[1]
    original_pattern = stale.GetSelectionItemPattern()
    original_pattern.Select = lambda **kwargs: pytest.fail("stale choice")
    stale.GetSelectionItemPattern = lambda: original_pattern

    def query(**selector):
        result = form.query(**selector)
        if "name" not in selector:
            form.controls[1] = form.choice("朋友圈")
        return result

    form.driver._find_scoped_controls = query
    form.driver.set_friend_fields(None, "")
    assert form.calls == [("select", "朋友圈")]


@pytest.mark.parametrize("failure", ["no_change", "false", "stale"])
def test_selection_failure_never_uses_mouse_fallback(permission_form, failure):
    form = permission_form

    def select(**kwargs):
        form.calls.append("select")
        if failure == "stale":
            raise RuntimeError("UIA element not available")
        return failure != "false"

    pattern = form.controls[1].GetSelectionItemPattern()
    pattern.Select = select
    form.controls[1].GetSelectionItemPattern = lambda: pattern
    with pytest.raises(AutomationRetryError) as raised:
        form.driver.set_friend_fields(None, "")
    assert raised.value.code == "FRIEND_PERMISSION_UNVERIFIED"
    assert form.calls == ["select"]


@pytest.mark.parametrize("error", [WeixinUnresponsiveError, ActionDeadlineExceeded])
def test_permission_stop_errors_propagate_without_selection(permission_form, error):
    form = permission_form
    form.driver.ensure_window_responsive = lambda *args: (_ for _ in ()).throw(error("stop"))
    with pytest.raises(error):
        form.driver.set_friend_fields(None, "")
    assert form.calls == []


def test_submit_rechecks_permission_without_selecting_it(permission_form, monkeypatch):
    form = permission_form
    form.driver.set_friend_fields(None, "")
    form.state["朋友圈"] = False
    monkeypatch.setattr(form.driver, "_process_windows", lambda *args, **kwargs: [303])
    with pytest.raises(AutomationRetryError) as raised:
        form.driver.submit_friend_request()
    assert raised.value.code == "FRIEND_PERMISSION_UNVERIFIED"
    assert raised.value.destructive_triggered is False
    assert form.calls == [("select", "朋友圈")]


def test_required_permission_disappearance_before_submit_is_not_ordinary_form(permission_form, monkeypatch):
    form = permission_form
    form.driver.set_friend_fields(None, "")
    form.controls[:] = [c for c in form.controls if c.ControlTypeName == "EditControl"]
    monkeypatch.setattr(form.driver, "_process_windows", lambda *args, **kwargs: [303])
    with pytest.raises(AutomationRetryError) as raised:
        form.driver.submit_friend_request()
    assert raised.value.code == "FRIEND_PERMISSION_UNVERIFIED"
    assert raised.value.destructive_triggered is False


def test_permission_query_never_falls_back_to_legacy_tree_walk(permission_form):
    form = permission_form
    form.driver._query = None
    form.driver._find_scoped_controls = lambda **kwargs: pytest.fail("no legacy query")
    with pytest.raises(AutomationRetryError) as raised:
        form.driver._ensure_friend_permission()
    assert raised.value.code == "FRIEND_PERMISSION_UNVERIFIED"


@pytest.mark.parametrize("property_name,value", [
    ("ProcessId", 999), ("NativeWindowHandle", 404),
    ("ClassName", "mmui::MainWindow"), ("IsOffscreen", True), ("IsEnabled", False),
])
def test_permission_refuses_wrong_or_inactive_window(permission_form, property_name, value):
    form = permission_form
    setattr(form.root, property_name, value)
    with pytest.raises(AutomationRetryError) as raised:
        form.driver.set_friend_fields(None, "")
    assert raised.value.code == "FRIEND_PERMISSION_UNVERIFIED"
    assert form.calls == []


def test_manual_choice_during_fresh_resolution_is_preserved(permission_form):
    form = permission_form
    observations = [0]

    def query(**selector):
        result = form.query(**selector)
        if "name" not in selector:
            observations[0] += 1
            if observations[0] == 2:
                form.state["仅聊天"] = True
        return result

    form.driver._find_scoped_controls = query
    form.driver.set_friend_fields(None, "")
    assert form.calls == []
    assert form.state["仅聊天"] is True


def test_manual_choice_during_final_pattern_acquisition_is_preserved(permission_form):
    form = permission_form
    calls = [0]
    get_pattern = form.controls[1].GetSelectionItemPattern

    def acquire_pattern():
        calls[0] += 1
        if calls[0] == 3:
            form.state["仅聊天"] = True
        return get_pattern()

    form.controls[1].GetSelectionItemPattern = acquire_pattern
    form.driver.set_friend_fields(None, "")
    assert form.state == {"朋友圈": False, "仅聊天": True}
    assert form.calls == []


def test_unsupported_prompt_and_choices_cannot_be_treated_as_normal_form(permission_form):
    form = permission_form
    form.controls[0].ControlTypeName = "PaneControl"
    for control in form.controls[1:3]:
        control.ControlTypeName = "CheckBoxControl"
    run = run_permission_batch(form, submit=True)
    assert run.result["done"] == run.result["error"] == 1
    assert run.driver.friend_submit_count == 0
    assert form.calls == []


def test_permission_property_scan_checks_deadline_between_reads(permission_form, monkeypatch):
    form = permission_form
    now = [0.0]
    reads = []
    monkeypatch.setattr("app.agent.waiters.time.monotonic", lambda: now[0])

    class SlowLabel:
        ControlTypeName = "TextControl"
        IsOffscreen = False
        IsEnabled = True

        @property
        def Name(self):
            reads.append("name")
            now[0] += 1.0
            return "unrelated label"

    form.driver._find_scoped_controls = lambda **kwargs: [SlowLabel() for _ in range(128)]
    with action_deadline():
        with pytest.raises(ActionDeadlineExceeded):
            form.driver._ensure_friend_permission()
        now[0] = 1.0
    assert len(reads) <= 15


def test_selection_state_cannot_be_assumed_when_readback_throws(permission_form):
    form = permission_form

    class BrokenPattern:
        @property
        def IsSelected(self):
            raise RuntimeError("private provider detail must not reach the user")

    form.controls[1].GetSelectionItemPattern = lambda: BrokenPattern()
    with pytest.raises(AutomationRetryError) as raised:
        form.driver.set_friend_fields(None, "")
    assert raised.value.code == "FRIEND_PERMISSION_UNVERIFIED"
    assert "private" not in str(raised.value)
    assert form.calls == []


def test_parent_group_can_be_used_when_selection_container_is_absent(permission_form):
    form = permission_form
    for control in form.controls[1:3]:
        pattern = control.GetSelectionItemPattern()
        pattern.SelectionContainer = None
        control.GetSelectionItemPattern = lambda value=pattern: value
    form.driver.set_friend_fields(None, "")
    assert form.calls == [("select", "朋友圈")]


def test_proxy_release_clears_previous_forms_required_permission(permission_form):
    form = permission_form
    form.driver.set_friend_fields(None, "")
    assert form.driver._friend_permission_required is True
    form.driver._release_control_proxies()
    assert form.driver._friend_permission_required is False


@pytest.mark.parametrize("cancel_changes_window", [True, False])
def test_real_preflight_cancel_clears_required_state(permission_form, monkeypatch, cancel_changes_window):
    form = permission_form
    form.driver.set_friend_fields(None, "")
    visible = [True]

    def close(**kwargs):
        visible[0] = False
        return True

    cancel = NS(GetInvokePattern=lambda: NS(Invoke=close if cancel_changes_window else lambda **kwargs: True))
    form.root.GetWindowPattern = lambda: NS(Close=close)
    form.driver._wait_control = lambda **kwargs: cancel
    form.driver._wait_for = lambda predicate, *args, **kwargs: predicate()
    monkeypatch.setattr("win32gui.IsWindow", lambda hwnd: visible[0])
    monkeypatch.setattr("win32gui.IsWindowVisible", lambda hwnd: visible[0])
    assert form.driver.cancel_friend_request() is True
    assert form.driver._verify_hwnd == 0
    assert form.driver._friend_permission_required is False
    assert form.calls == [("select", "朋友圈")]


def run_permission_batch(form, *, submit=False, control=None, before_submit=None):
    driver = FakeDriver()
    driver.set_friend_fields = form.driver.set_friend_fields
    cleaned = []
    driver.finish_task = lambda: cleaned.append("cleanup") or {"success": True}
    driver.submit_friend_request = before_submit or driver.submit_friend_request
    events = []
    engine = WeixinWorkflowEngine(driver_factory=lambda: driver, friend_submit_enabled=True)
    task = TaskRequest(
        task_id="permission-test", kind="friend_add",
        items=(TaskItem("one", account="mock_one"), TaskItem("two", account="mock_two")),
        options=TaskOptions(submit_friend_request=submit),
    )
    result = engine.run(task, control or TaskControl(), lambda method, payload: events.append((method, payload)))
    return NS(driver=driver, result=result, events=events, cleaned=cleaned)


@pytest.mark.parametrize("submit", [False, True])
def test_invalid_permission_stops_batch_without_retry_or_submission(permission_form, submit):
    form = permission_form
    form.controls.pop(2)
    run = run_permission_batch(form, submit=submit)
    assert run.result["done"] == run.result["error"] == 1
    assert run.result["unknown"] == 0
    assert run.driver.friend_submit_count == 0
    assert run.driver.soft_refresh_count == 0
    assert len(run.cleaned) == 1
    failures = [p for m, p in run.events if m == "task.event" and p["outcome"] == "error"]
    assert failures[-1]["errorCode"] == "FRIEND_PERMISSION_UNVERIFIED"
    assert failures[-1]["recoverable"] is False
    assert not any(p.get("itemId") == "two" for m, p in run.events if m == "task.event")


def test_preflight_selects_permission_but_cancels_without_submitting(permission_form):
    run = run_permission_batch(permission_form)
    assert run.result["success"] == 2
    assert run.driver.friend_cancel_count == 2
    assert run.driver.friend_submit_count == 0
    assert permission_form.calls == [("select", "朋友圈")]


def test_stop_after_permission_selection_never_submits_or_advances(permission_form):
    form = permission_form
    control = TaskControl()
    pattern = form.controls[1].GetSelectionItemPattern()
    select = pattern.Select

    def select_and_stop(**kwargs):
        result = select(**kwargs)
        control.request_stop()
        return result

    pattern.Select = select_and_stop
    form.controls[1].GetSelectionItemPattern = lambda: pattern
    run = run_permission_batch(form, submit=True, control=control)
    assert run.driver.friend_submit_count == 0
    assert run.result["done"] == 1
    assert len(run.cleaned) == 1


def test_permission_lost_at_submit_stops_batch_as_not_triggered(permission_form, monkeypatch):
    form = permission_form
    monkeypatch.setattr(form.driver, "_process_windows", lambda *args, **kwargs: [303])

    def submit_after_choice_lost():
        form.state["朋友圈"] = False
        return form.driver.submit_friend_request()

    run = run_permission_batch(form, submit=True, before_submit=submit_after_choice_lost)
    assert run.result["done"] == run.result["error"] == 1
    assert run.result["unknown"] == 0
    assert form.calls == [("select", "朋友圈")]
    assert len(run.cleaned) == 1
    failures = [p for m, p in run.events if m == "task.event" and p["outcome"] == "error"]
    assert failures[-1]["errorCode"] == "FRIEND_PERMISSION_UNVERIFIED"
    assert failures[-1]["destructiveBoundaryCrossed"] is False


def test_permission_wait_obeys_shared_action_deadline(permission_form, monkeypatch):
    form = permission_form
    now = [0.0]
    monkeypatch.setattr("app.agent.waiters.time.monotonic", lambda: now[0])
    pattern = form.controls[1].GetSelectionItemPattern()

    def select_and_expire(**kwargs):
        form.calls.append("select")
        now[0] = 16.0
        return True

    pattern.Select = select_and_expire
    form.controls[1].GetSelectionItemPattern = lambda: pattern
    with action_deadline():
        with pytest.raises(ActionDeadlineExceeded):
            form.driver.set_friend_fields(None, "")
        now[0] = 1.0
    assert form.calls == ["select"]
