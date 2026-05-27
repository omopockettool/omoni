#!/bin/sh
set -eu

ROOT="${1:-.}"

echo "Scanning for architecture red flags"

rg -n --hidden --glob '!.git' --glob '!build' --glob '!DerivedData' \
  'import CoreData|@Environment\(\\\.managedObjectContext\)|ObservableObject|@Published|NSFetchRequest|context\.perform|Task \{ await load|onAppear \{ repairStateAfterPresentation' \
  "$ROOT"
