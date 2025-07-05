# Localization plugin

1. [Requirements](#1-requirements)
2. [Translate](#2-translate)

## 1. Requirements

- Python 3

Install the requirements needed using pip:

```sh
pip install -r requirements.tx
```

Configure your openapi key in a .env file:

```sh
export OPENAI_API_KEY="your_api_key_here"
```

## 2. Translate

Go to the `localization_script` folder:

```sh
cd addons/blazium_shared_menus/localization_script
```

Run `translate.py` from `localization_script` folder. The second argument is the word or phrase you want translated

```sh
python translate.py dog
# or
python translate.py "two dogs"
```

You will see:

```sh
Wrote 30 translations to input.csv.
```

In the input.csv file there will be the resulting translations:

```js
lang,translation
hu,macska
uk,кіт
cs,kočka
...
```

Then run `update_files.py` with the msg_id as first param, and optionally the path to lang folder, eg:

```sh
python update_files.py message_id
# or
python update_files.py message_id ../lang # for shared_menus lang
# or
python update_files.py message_id ../../../lang # for project translation
```

