import csv
import os

if len(os.sys.argv) > 1:
    msg_id = os.sys.argv[1]
else:
    print("No msg_id provided.")
    exit(1)
# Readt input.csv file
with open("input.csv", "r") as f:
    reader = csv.DictReader(f)
    translations = {row['lang']: row['translation'] for row in reader}
    translations["localization"] = ""
    for lang, translation in translations.items():
        po_file_path = f"../lang/{lang}.po"
        with open(po_file_path, "a") as po_file:
            po_file.write(f'\n')
            po_file.write(f'msgid "{msg_id}"\n')
            po_file.write(f'msgstr "{translation}"\n')
        print(f"Created {po_file_path} with translation for {lang}.")
