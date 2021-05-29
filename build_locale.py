import argparse
import os
import shutil
import stat

class bcolors:
	HEADER = '\033[95m'
	OKBLUE = '\033[94m'
	OKCYAN = '\033[96m'
	OKGREEN = '\033[92m'
	WARNING = '\033[93m'
	FAIL = '\033[91m'
	ENDC = '\033[0m'
	BOLD = '\033[1m'
	UNDERLINE = '\033[4m'

def print_clr (text, is_error=False):
	if is_error:
		print (f"{bcolors.FAIL}" + text + f"{bcolors.ENDC}")
	else:
		print (f"{bcolors.OKGREEN}" + text + f"{bcolors.ENDC}")

def find_and_set (dct, name, value):
	for k,v in dct.items ():
		if v['name'] == name:
			v['value'] = value
			return

	print_clr ('string not found: "' + name + '"',  True)

# Colored terminal fix
os.system ('')

parser = argparse.ArgumentParser (add_help=False, description='Build project locale.')
parser.add_argument ('--name-short', help='project short name', required=True)

args = parser.parse_args ()

APP_NAME_SHORT=args.name_short

# Set current script configuration
CURRENT_DIRECTORY = os.path.dirname (os.path.abspath (__file__))
PROJECT_DIRECTORY = os.path.join (CURRENT_DIRECTORY, '..', APP_NAME_SHORT)
I18N_DIRECTORY = os.path.join (PROJECT_DIRECTORY, 'bin', 'i18n')
LOCALE_FILE = os.path.join (PROJECT_DIRECTORY, 'bin', APP_NAME_SHORT + '.lng')
RESOURCE_H = os.path.join (PROJECT_DIRECTORY, 'src', 'resource.h')
RESOURCE_RC = os.path.join (PROJECT_DIRECTORY, 'src', 'resource.rc')

# Check configuration is right
if not os.path.isdir (PROJECT_DIRECTORY):
	print_clr ('Binaries directory "' + PROJECT_DIRECTORY + '" was not found.',  True)
	os.sys.exit ()

if not os.path.isfile (RESOURCE_H):
	print_clr ('Project resource header "' + PROJECT_DIRECTORY + '" was not found.',  True)
	os.sys.exit ()

if not os.path.isfile (RESOURCE_RC):
	print_clr ('Project resource "' + PROJECT_DIRECTORY + '" was not found.',  True)
	os.sys.exit ()

ID_ACCELERATOR = 1
ID_CONTROL = 100
ID_DIALOG = 100
ID_ICON = 100
ID_RCDATA = 1
ID_STRING = 1
ID_PTR = 100

strings_array = {}
locale_lastname = ''
locale_timestamp = 0

# Update resource header
print_clr ('Update resource header...');

with open (RESOURCE_H, 'r') as fn:
	lines = fn.readlines ()
	fn.close ()

	f_out = open (RESOURCE_H, 'w')

	for ln in lines:
		if not ln.startswith ('#define '):
			f_out.write (ln)

		else:
			var = ln.split (' ')

			if len (var) != 3 or not var[1] or not var[2] or not var[2].strip ().isdigit ():
				f_out.write (ln)

			else:
				res_name = var[1].strip ()
				res_id = int (var[2].strip ())

				if res_name.startswith ('IDC_') or res_name.startswith ('IDM_'):
					res_id = ID_CONTROL
					ID_CONTROL += 1

				elif res_name.startswith ('IDS_'):
					res_id = ID_STRING
					ID_STRING += 1

					strings_array[str (res_id)] = {'name': res_name, 'value': ''}

				elif res_name.startswith ('IDI_'):
					res_id = ID_ICON
					ID_ICON += 1

				elif res_name.startswith ('IDD_'):
					res_id = ID_DIALOG
					ID_DIALOG += 1

				elif res_name.startswith ('IDR_'):
					res_id = ID_RCDATA
					ID_RCDATA += 1

				elif res_name.startswith ('IDA_'):
					res_id = ID_ACCELERATOR
					ID_ACCELERATOR += 1

				elif res_name.startswith ('IDP_'):
					res_id = ID_PTR
					ID_PTR += 1

				f_out.write ('#define ' + res_name + ' ' + str (res_id) + '\n')

	f_out.close ()

if not len (strings_array):
	print_clr ('Dictionary is empty.',  True)
	os.sys.exit ()

# Load strings
print_clr ('Load strings...');

with open (RESOURCE_RC, 'r') as fn:
	lines = fn.readlines ()

	for line in lines:
		line = line.strip ('\t\r\n ')

		if line.startswith ('IDS_'):
			part = line.partition (' ')

			if part[0] and part[2]:
				key = part[0].strip ('\t "')
				val = part[2].replace ('""', '"').strip ('\t "')

				if key and val:
					find_and_set (strings_array, key, val)

	fn.close ()

# Create locale example file
print_clr ('Create locale example file...');

with open (os.path.join (I18N_DIRECTORY, '!example.txt'), 'w', encoding='utf-16') as fn:
	fn.write ('; <language name>\n' + '; <author information>' + '\n\n' + '[<locale name here>]\n')

	for k,v in strings_array.items ():
		if v['value']:
			fn.write (v['name'] + '=' + v['value'] + '\n')

	fn.close ()

if not os.path.isdir (I18N_DIRECTORY):
	print_clr ('Locale directory "' + I18N_DIRECTORY + '" was not found...');

else:

	# Get localization timestamp
	print_clr ('Get localization timestamp...');

	i18n_files = os.listdir (I18N_DIRECTORY)

	for f in i18n_files:
		if not f.endswith ('.ini'):
			continue

		locale_name = os.path.splitext (f)[0]
		locale_path = os.path.join (I18N_DIRECTORY, f)

		lastmod = int (os.path.getmtime (locale_path));

		if lastmod > locale_timestamp:
			locale_timestamp = lastmod
			locale_lastname = locale_name

	# Enumerate localizations
	print_clr ('Enumerate localizations...');

	lng_content = '; ' + APP_NAME_SHORT + '\n'
	lng_content = lng_content + '; https://github.com/henrypp/' + APP_NAME_SHORT + '/tree/master/bin/i18n\n'
	lng_content = lng_content + ';\n; DO NOT MODIFY THIS FILE -- YOUR CHANGES WILL BE ERASED!\n\n'

	for f in i18n_files:
		if not f.endswith ('.ini'):
			continue

		locale_name = os.path.splitext (f)[0]
		locale_path = os.path.join (I18N_DIRECTORY, f)

		print ('Processing "' + locale_name + '" locale...')

		with open (locale_path, mode='r', encoding='utf-16') as ini_file:
			lines = ini_file.readlines ()
			ini_file.close ()

			# Get locale structure
			locale_content = ''
			locale_desc = ''
			locale_array = {}

			for line in lines:
				if line.startswith (';'):
					locale_desc = locale_desc + line
				else:
					break

			if locale_desc:
				locale_desc = locale_desc + '\n'

			# Write locale header
			locale_content = locale_content + locale_desc + '[' + locale_name + ']\n'
			lng_content = lng_content + locale_desc + '[' + locale_name + ']\n'

			# Write locale timestamp
			if locale_name.lower () == 'russian':
				lng_content = lng_content + '000=' + str (locale_timestamp) + '\n'

			# Parse locale string array
			for line in lines:
				line = line.strip ('\t\n ')

				if line.startswith (';'):
					continue

				part = line.partition ('=')

				if part[0] and part[2]:
					key = part[0].strip ('\t\n ');
					value = part[2].strip ('\t\n ');

					locale_array[key] = value

			# Write parsed locale array into a file
			for k,v in strings_array.items ():
				if not v['value']:
					continue

				key = v['name']
				number_key = '{:03}'.format (int (k))

				if number_key in locale_array:
					value = locale_array[number_key]

				elif key in locale_array:
					value = locale_array[key]

				else:
					value = v['value']

				locale_content = locale_content + key + '=' + value + '\n'

				if value != v['value']:  # write only localized strings
					lng_content = lng_content + number_key + '=' + value + '\n'

			# Line-ending hack
			if i18n_files[-1] != f:
				lng_content = lng_content + '\n'

			# Write updated language template
			filemtime = os.path.getmtime (locale_path);

			with open (locale_path, 'w', encoding='utf-16') as ini_file:
				ini_file.write (locale_content)
				ini_file.close ()

			os.utime (locale_path, (filemtime, filemtime))

	# Write updated language content
	if os.path.isfile (LOCALE_FILE):
		os.chmod (LOCALE_FILE, stat.S_IWRITE)

		with open (LOCALE_FILE, 'w', encoding='utf-16') as lng_file:
			lng_file.write (lng_content)
			lng_file.close ()

		shutil.copyfile (LOCALE_FILE, os.path.join (PROJECT_DIRECTORY, 'bin', '32', APP_NAME_SHORT + '.lng'))
		shutil.copyfile (LOCALE_FILE, os.path.join (PROJECT_DIRECTORY, 'bin', '64', APP_NAME_SHORT + '.lng'))

print ('\nLocale timestamp: ' + str (locale_timestamp) + ' (' + locale_lastname + ').')
