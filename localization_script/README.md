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
python localize.py
```

Copy the resulting csv file (if its correct), into input.csv file. Keep the header. The file should have 31 lines. It should look like:

```js
lang,translation
hu,macska
uk,кіт
cs,kočka
```
