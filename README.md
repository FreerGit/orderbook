# money
A floating point representation of Money, with 15 digits of guaranteed precision. Money is represented with an f64 with units of 10^-6.

## Install
You can simply copy the code into a new package or usage something like git subtree
```console
git subtree pull --prefix subtree_directory https://github.com/freergit/money main --squash
```

## Notes
The multiplying and dividing procedures (with Money or f64) may be entirely nonsensical, haven't decided the use case yet.

I will probaly expose a function that allows for division/multiplication with uint, again this will be used carefully otherwise big bad.