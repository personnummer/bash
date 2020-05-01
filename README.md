# bash-personnummer

Validate Swedish [personal identity
numbers](https://en.wikipedia.org/wiki/Personal_identity_number_(Sweden)) with
[bash](https://www.gnu.org/software/bash/)

## Usage

The available methods are `valid`, `format [bool:long]`, `get_age`, `is_femal`,
`is_male` and `is_coordination_number`.

The API allows you to pass the personal identification number as an *optional*
argument for all methods except `valid`. The code stores the parsed values
interally (in variables prefixed with `__personnummer` to avoid collision) so as
long as you start by calling `valid` (or the "internal" method `__parse` you can
omit the argument.

Special case for `format` which takes a "boolean" (true-ish) value to format to
long version. Although this is also handled which makes the way this method is
called handled three cases.

**Implicit usage without passing arugment**

```bash
#!/usr/bin/env bash

set -eu

source personnummer.sh

some_input="${1:-}"
if ! valid "$some_input"; then
  echo "invalid input"
  exit 1
fi

gender="$(is_female && echo "female" || echo "male")"

printf "> The person with personal identity number %s is a %s of age %d\n" \
  "$(format)" "$gender" "$(get_age)"
```

```sh
$ my_program.sh 19900101-0017
> The person with personal identity number 900101-0017 is a male of age 30
```

**A more explicit way**

```bash
#!/usr/bin/env bash

set -eu

source personnummer.sh

# Getting gender with personal identification number as argument.
[ is_male "9001010017" ] && echo "It's a male"

# Formatting a personal identification number.
format "9001010017"   # 900101-0017
format "9001010017" 1 # 19900101-0017

# Validate to allow implicit usage.
valid "199001010017"
format                # 900101-0017
format 1              # 19900101-0017

# Get the age explicitly.
echo "The person is $(get_age "9001010017") years old"

# Check coordination number explicitly.
[ is_coordination_number "90010161+0017" ] && echo "It's a coordinational number"
```

## Testing

Testing is done with [critic.sh](https://github.com/Checksum/critic.sh) which is
bundled in the repository. Just run `test.sh` for testing.
