import 'package:flutter/material.dart';
import 'plugin_interface.dart';

/// 插件基类，提供默认实现
abstract class BasePlugin implements IPlugin {
  bool _initialized = false;
  bool _enabled = false;

  bool get isInitialized => _initialized;
  bool get isEnabled => _enabled;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    await onInitialize();
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    
    if (_enabled) {
      await onDisable();
    }
    
    await onDispose();
    _initialized = false;
  }

  @override
  Future<void> onEnable() async {
    if (!_initialized || _enabled) return;
    
    await onPluginEnable();
    _enabled = true;
  }

  @override
  Future<void> onDisable() async {
    if (!_enabled) return;
    
    await onPluginDisable();
    _enabled = false;
  }

  /// 子类需要实现的初始化方法
  Future<void> onInitialize() async {}

  /// 子类需要实现的销毁方法
  Future<void> onDispose() async {}

  /// 子类需要实现的启用方法
  Future<void> onPluginEnable() async {}

  /// 子类需要实现的禁用方法
  Future<void> onPluginDisable() async {}
}