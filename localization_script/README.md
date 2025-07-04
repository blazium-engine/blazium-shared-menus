# Localization plugin

## Requirements

```sh
pip install -r requirements.tx
```

or

```sh
pip i openai
```

Configure your openapi key:

```sh
export OPENAI_API_KEY="your_api_key_here"
```

## Run

Run it locally.

```sh
python localize.py word
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

Then run `update_files.py` with the msg_id as first param, eg:

```sh
python update_files.py cat_message
```

