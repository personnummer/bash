# bash-personnummer

Validate Swedish social security numbers with
[bash](https://www.gnu.org/software/bash/)

## Usage

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

printf "> The person with social security number %s is a %s of age %d\n" \
  "$(format)" "$gender" "$(get_age)"
```

```sh
$ my_program.sh 19900101-0017
> The person with social security number 900101-0017 is a male of age 30
```

## Testing

Testing is done with [critic.sh](https://github.com/Checksum/critic.sh) which is
bundled in the repository. Just run `test.sh` for testing.
