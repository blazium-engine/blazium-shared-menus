import csv
import os
import polib

folder_path = "../lang"
if len(os.sys.argv) > 1:
    msg_id = os.sys.argv[1]
    if len(os.sys.argv) > 2:
        folder_path = os.sys.argv[2]
    else:
        print("No folder_path provided, using default '../lang'.")
else:
    print("No msg_id provided.")
    exit(1)
# Readt input.csv file
with open("input.csv", "r") as f:
    reader = csv.DictReader(f)
    translations = {row['lang']: row['translation'] for row in reader}
    translations["localization"] = ""
    for lang, translation in translations.items():
        po_file_path = f"{folder_path}/{lang}.po"
        pofile = polib.pofile(po_file_path, check_for_duplicates=True)
        pofile.append(polib.POEntry(msgid=msg_id, msgstr=translation))
        pofile.sort()
        pofile.save(po_file_path)
        print(f"Created {po_file_path} with translation for {lang}.")
