import json

import settings


def test_init_uses_config_file_from_environment(monkeypatch, tmp_path):
    config_path = tmp_path / "config.json"
    config_path.write_text(json.dumps({"nbe_serial": "test-device"}), encoding="utf-8")
    monkeypatch.setenv("NBE_CONFIG_FILE", str(config_path))

    settings.init()

    assert settings.config["nbe_serial"] == "test-device"


def test_safe_config_redacts_credentials():
    settings.config = {
        "mqtt_pass": "mqtt-secret",
        "nbe_ip": "192.0.2.1",
        "nbe_pass": "burner-secret",
    }

    safe_config = settings.safe_config()

    assert safe_config == {
        "mqtt_pass": "<redacted>",
        "nbe_ip": "192.0.2.1",
        "nbe_pass": "<redacted>",
    }