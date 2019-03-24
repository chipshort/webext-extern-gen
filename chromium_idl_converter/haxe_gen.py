#! /usr/bin/env python2

import os.path
import os
import glob
import sys
import json
#Import chromium's internal schema parser
_current_path = os.path.dirname(os.path.realpath(__file__))
_generators = os.path.join(_current_path, "generators")
if (_current_path in sys.path) and (_generators in sys.path):
  from json_schema_compiler import idl_schema
else:
  sys.path.insert(0, _current_path)
  sys.path.insert(0, _generators)
  try:
    from json_schema_compiler import idl_schema
  finally:
    sys.path.pop(0)
    sys.path.pop(0)

#Convert all IDL files to json
print "Converting IDL files to JSON..."
os.chdir("chrome_schemas")
counter = 0
for file in glob.glob("*.idl"):
    schema = idl_schema.Load(file)
    jsonFile = os.path.splitext(file)[0] + ".json"
    f = open(jsonFile, "w")
    f.write(json.dumps(schema, indent=2))
    f.close()
    counter += 1

print "Converted " + `counter` + " IDL files"