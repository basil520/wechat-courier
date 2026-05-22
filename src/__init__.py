# -*- coding: utf-8 -*-
"""wx4py public package exports."""

from importlib import import_module

from ._version import __version__

__author__ = "wx4py Team"

_LAZY_EXPORTS = {
    "WeChatClient": (".client", "WeChatClient"),
    "AIClient": (".ai", "AIClient"),
    "AIConfig": (".ai", "AIConfig"),
    "AIResponder": (".ai", "AIResponder"),
    "ForwardPayload": (".features.messaging.forwarder", "ForwardPayload"),
    "ForwardRuleHandler": (".features.messaging.forwarder", "ForwardRuleHandler"),
    "ForwardTarget": (".features.messaging.forwarder", "ForwardTarget"),
    "GroupForwardRule": (".features.messaging.forwarder", "GroupForwardRule"),
    "MessageEvent": (".features.messaging.listener", "MessageEvent"),
    "WeChatGroupListener": (".features.messaging.listener", "WeChatGroupListener"),
    "AsyncCallbackHandler": (".features.messaging.processor", "AsyncCallbackHandler"),
    "CallbackHandler": (".features.messaging.processor", "CallbackHandler"),
    "ForwardAction": (".features.messaging.processor", "ForwardAction"),
    "MessageAction": (".features.messaging.processor", "MessageAction"),
    "MessageHandler": (".features.messaging.processor", "MessageHandler"),
    "ReplyAction": (".features.messaging.processor", "ReplyAction"),
    "WeChatGroupProcessor": (".features.messaging.processor", "WeChatGroupProcessor"),
    "ControlNotFoundError": (".core.exceptions", "ControlNotFoundError"),
    "RegistryError": (".core.exceptions", "RegistryError"),
    "TargetNotFoundError": (".core.exceptions", "TargetNotFoundError"),
    "WeChatError": (".core.exceptions", "WeChatError"),
    "WeChatNotConnectedError": (".core.exceptions", "WeChatNotConnectedError"),
    "WeChatNotFoundError": (".core.exceptions", "WeChatNotFoundError"),
}

__all__ = ["__version__", *_LAZY_EXPORTS]


def __getattr__(name):
    if name not in _LAZY_EXPORTS:
        raise AttributeError(f"module {__name__!r} has no attribute {name!r}")

    module_name, attribute_name = _LAZY_EXPORTS[name]
    value = getattr(import_module(module_name, __name__), attribute_name)
    globals()[name] = value
    return value


def __dir__():
    return sorted(__all__)
