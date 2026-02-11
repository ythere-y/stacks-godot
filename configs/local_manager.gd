# LocaleManager.gd (可以挂载为一个 Autoload 单例)
extends Node

func set_language(index: int):
    match index:
        0:
            TranslationServer.set_locale("zh")
        1:
            TranslationServer.set_locale("en")
    
    # 保存配置到本地，下次启动自动加载
    save_language_setting(TranslationServer.get_locale())

func save_language_setting(locale: String):
    var config = ConfigFile.new()
    config.set_value("settings", "locale", locale)
    config.save("user://settings.cfg")

func load_language_setting():
    var config = ConfigFile.new()
    if config.load("user://settings.cfg") == OK:
        var locale = config.get_value("settings", "locale", "zh")
        TranslationServer.set_locale(locale)