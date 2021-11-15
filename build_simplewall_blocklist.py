import xml.dom.minidom

import argparse
from helper import *

parser = argparse.ArgumentParser (add_help=False, description='Update internal rules.')
parser.add_argument ('--name-short', help='project short name', required=True)

args = parser.parse_args ()

APP_NAME_SHORT=args.name_short

CURRENT_DIRECTORY = os.path.dirname (os.path.abspath (__file__))
RULES_DIR = os.path.join (CURRENT_DIRECTORY, '..', '!repos', 'WindowsSpyBlocker', 'data', 'firewall')
PROJECT_DIRECTORY = os.path.join (CURRENT_DIRECTORY, '..', APP_NAME_SHORT)
RULES_FILE = os.path.join (PROJECT_DIRECTORY, 'bin', 'profile_internal.xml')
RULES_FILE_PACKED = os.path.join (PROJECT_DIRECTORY, 'bin', 'profile_internal_packed.bin')

check_path_with_status ('Profile directory', PROJECT_DIRECTORY)
check_path_with_status ('WSB directory', RULES_DIR)
check_path_with_status ('Profile file', RULES_FILE, True)

# Open profile xml
with open (RULES_FILE, 'r', newline='') as f:
	data = f.read ()

	if not data:
		raise Exception ('File reading failure: ' + RULES_FILE)

	# toprettyxml() hack
	data = data.replace ('\n', '')
	data = data.replace ('\t', '')

	xml_doc = xml.dom.minidom.parseString (data)
	xml_root = xml_doc.getElementsByTagName ("root")

	f.close ()

# Store timestamp
timestamp = int (xml_root[0].getAttribute ('timestamp'))

# Cleanup xml
for node in xml_doc.getElementsByTagName ('rules_blocklist'):
	parent = node.parentNode
	parent.removeChild (node)

xml_root[0].appendChild (xml_doc.createElement ('rules_blocklist'))
xml_section = xml_doc.getElementsByTagName ('rules_blocklist')

if not xml_section:
	raise Exception ('Parse xml failure.')

total_rules_count = 0

# Enumerate Windows Spy Blocker spy/extra and update rules
for file_name in os.listdir (RULES_DIR):
	module_name = os.path.splitext (file_name)[0]
	module_path = os.path.join (RULES_DIR, file_name)

	log_status (status.TITLE, 'Parsing "' + module_name + '" rules')

	lastmod = int (os.path.getmtime (module_path));

	if lastmod > timestamp:
		timestamp = lastmod;

	with open (module_path, 'r') as f:
		rows = f.readlines ()
		natural_sort (rows)
		f.close ()

		count = 0

		for string in rows:
			line = string.strip ("\n\r\t ")

			if not line or line.startswith ('#') or line.startswith ('<') or line.startswith ('>') or line.startswith ('='):
				continue

			count += 1

			new_item = xml_doc.createElement ('item')

			new_item.setAttribute ('name', module_name + '_' + line)
			new_item.setAttribute ('rule', line)

			xml_section[0].appendChild (new_item)

		log_status (status.SUCCESS, 'Found %i %s rules...' % (count, module_name))

		total_rules_count += count

# Set new rule timestamp
xml_root[0].setAttribute ('timestamp', str (timestamp))

# Save updated profile xml
data = xml_doc.toprettyxml (indent="\t", newl="\n")

if data:
	data = data.replace ('/>', ' />')

	with open (RULES_FILE, 'w', newline='') as fn:
		fn.write (data)
		fn.close ()

print ('\r')

# Compress file
pack_file_lznt (RULES_FILE, RULES_FILE_PACKED)

print ('\nBlocklist rules count: %s\nBlocklist timetamp: %s\n' % (str (total_rules_count), str (timestamp)))
