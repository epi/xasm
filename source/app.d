// xasm 3.1.0 by Piotr Fusik <fox@scene.pl>
// http://xasm.atari.org
// Can be compiled with DMD v2.073.

// Poetic License:
//
// This work 'as-is' we provide.
// No warranty express or implied.
// We've done our best,
// to debug and test.
// Liability for damages denied.
//
// Permission is granted hereby,
// to copy, share, and modify.
// Use as is fit,
// free or for profit.
// These rights, on this notice, rely.

import xasm;

import std.stdio;
import std.algorithm;
import std.range;

pure bool isOption(string arg) {
	if (arg.length < 2) return false;
	if (arg[0] == '-') return true;
	if (arg[0] != '/') return false;
	if (arg.length == 2) return true;
	if (arg[2] == ':') return true;
	return false;
}

void setOption(char letter) {
	assert(letter >= 'a' && letter <= 'z');
	if (options[letter - 'a']) {
		exitCode = 3;
		return;
	}
	options[letter - 'a'] = true;
}

int main(string[] args) {
	for (int i = 1; i < args.length; i++) {
		string arg = args[i];
		if (isOption(arg)) {
			char letter = arg[1];
			if (letter >= 'A' && letter <= 'Z')
				letter += 'a' - 'A';
			switch (letter) {
			case 'c':
			case 'i':
			case 'm':
			case 'p':
			case 'q':
			case 'u':
				if (arg.length != 2)
					exitCode = 3;
				setOption(letter);
				break;
			case 'd':
				string definition = null;
				if (arg[0] == '/') {
					if (arg.length >= 3 && arg[2] == ':')
						definition = arg[3 .. $];
				} else if (i + 1 < args.length && !isOption(args[i + 1]))
					definition = args[++i];
				if (definition is null || find(definition, '=').empty)
					exitCode = 3;
				commandLineDefinitions ~= definition;
				break;
			case 'l':
			case 't':
			case 'o':
				setOption(letter);
				string filename = null;
				if (arg[0] == '/') {
					if (arg.length >= 3 && arg[2] == ':')
						filename = arg[3 .. $];
				} else if (i + 1 < args.length && !isOption(args[i + 1]))
					filename = args[++i];
				if (filename is null && (letter == 'o' || arg.length != 2))
					exitCode = 3;
				optionParameters[letter - 'a'] = filename;
				break;
			default:
				exitCode = 3;
				break;
			}
			continue;
		}
		if (sourceFilename !is null)
			exitCode = 3;
		sourceFilename = arg;
	}
	if (sourceFilename is null)
		exitCode = 3;
	if (!getOption('q'))
		writeln(TITLE);
	if (exitCode != 0) {
		write(
`Syntax: xasm source [options]
/c             Include false conditionals in listing
/d:label=value Define a label
/i             Don't list included files
/l[:filename]  Generate listing
/o:filename    Set object file name
/M             Print Makefile rule
/p             Print absolute paths in listing and error messages
/q             Suppress info messages
/t[:filename]  List label table
/u             Warn of unused labels
`);
		return exitCode;
	}
	try {
		assemblyPass();
		pass2 = true;
		assemblyPass();
		if (getOption('t') && labelTable.length > 0)
			listLabelTable();
	} catch (AssemblyError e) {
		warning(e.msg, true);
		exitCode = 2;
	}
	listingStream.close();
	objectStream.close();
	if (exitCode <= 1) {
		if (!getOption('q')) {
			writefln("%d lines of source assembled", totalLines);
			if (objectBytes > 0)
				writefln("%d bytes written to the object file", objectBytes);
		}
		if (getOption('m')) {
			writef("%s:", makeTarget);
			foreach (filename; makeSources)
				writef(" %s", makeEscape(filename));
			write("\n\txasm");
			for (int i = 1; i < args.length; i++) {
				string arg = args[i];
				if (isOption(arg)) {
					char letter = arg[1];
					if (letter >= 'A' && letter <= 'Z')
						letter += 'a' - 'A';
					switch (letter) {
					case 'm':
						break;
					case 'o':
						if (arg[0] == '/')
							writef(" /%c:$@", arg[1]);
						else {
							writef(" -%c $@", arg[1]);
							++i;
						}
						break;
					default:
						if (arg[0] == '-'
						 && (letter == 'd' || letter == 'l' || letter == 't')
						 && i + 1 < args.length && !isOption(args[i + 1])) {
							writef(" %s %s", arg, makeEscape(args[++i]));
						}
						else {
							writef(" %s", makeEscape(arg));
						}
						break;
					}
					continue;
				}
				write(" $<");
			}
			writeln();
		}
	}
	return exitCode;
}
