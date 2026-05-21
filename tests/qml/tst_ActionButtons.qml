import QtQuick
import QtTest
import "../../qml/components"
import "../../qml/theme"

TestCase {
    name: "ActionButtons"

    // Mock backend 对象
    QtObject {
        id: mockBackend
        property string phase: "idle"
        function start_sending() { mockBackend.phase = "running" }
        function pause_sending() { mockBackend.phase = "paused" }
        function resume_sending() { mockBackend.phase = "running" }
        function stop_sending() { mockBackend.phase = "done" }
        function reset() { mockBackend.phase = "idle" }
    }

    ActionButtons {
        id: buttonsWithBackend
        btnBackend: mockBackend
    }

    ActionButtons {
        id: buttonsStandalone
    }

    function test_button_height() {
        compare(buttonsStandalone.height, 32, "ActionButtons 高度应为 32")
    }

    function test_children_count_and_texts() {
        // 新结构：Item 包含一个 StackLayout，StackLayout 包含 4 个 Row（每阶段一个）
        compare(buttonsStandalone.children.length, 1, "应有 1 个 StackLayout 子元素")
        var stack = buttonsStandalone.children[0]
        compare(stack.children.length, 4, "StackLayout 应有 4 个阶段分组")
        // idle 组第 1 个按钮
        compare(stack.children[0].children[0].text, "开始发送")
        // running 组按钮
        compare(stack.children[1].children[0].text, "暂停")
        compare(stack.children[1].children[1].text, "停止")
        // paused 组按钮
        compare(stack.children[2].children[0].text, "继续")
        compare(stack.children[2].children[1].text, "停止")
        // done 组按钮
        compare(stack.children[3].children[0].text, "重新开始")
    }

    function test_default_phase_is_idle() {
        compare(buttonsStandalone.phase, "idle", "无 backend 时默认 phase 应为 idle")
    }

    function test_phase_follows_backend() {
        mockBackend.phase = "running"
        tryCompare(buttonsWithBackend, "phase", "running", 1000, "phase 应跟随 backend 变为 running")

        mockBackend.phase = "paused"
        tryCompare(buttonsWithBackend, "phase", "paused", 1000, "phase 应跟随 backend 变为 paused")

        mockBackend.phase = "done"
        tryCompare(buttonsWithBackend, "phase", "done", 1000, "phase 应跟随 backend 变为 done")

        mockBackend.phase = "idle"
        tryCompare(buttonsWithBackend, "phase", "idle", 1000, "phase 应跟随 backend 变为 idle")
    }

    function test_standalone_phase_can_be_set() {
        buttonsStandalone.phase = "running"
        compare(buttonsStandalone.phase, "running")

        buttonsStandalone.phase = "paused"
        compare(buttonsStandalone.phase, "paused")

        buttonsStandalone.phase = "done"
        compare(buttonsStandalone.phase, "done")
    }
}
