import os
import json


def safe_config():
  """Return configuration suitable for diagnostic logging."""
  hidden_words = ("pass", "password", "secret", "token")
  return {
    key: "<redacted>" if any(word in key.lower() for word in hidden_words) else value
    for key, value in sorted(config.items())
  }


def init():
    global config
    curr_path = os.path.dirname(os.path.realpath(__file__))
    config_file = os.environ.get("NBE_CONFIG_FILE", os.path.join(curr_path, "config.json"))
    print ("Checking if settings file exists: ",config_file)
    if (os.path.exists(config_file)):
      with open(config_file) as f:
        config = json.load(f)
        print ("File found, settings loaded!")
    else:
      print ("Settings file "+config_file+" does not exist!")
