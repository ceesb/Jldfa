# What is it?

This is a small library for doing DFA (differental fault attacks). Currently supports fault attacks on AES and DES. The library uses Jlsca, my other toy project, and since it's not part of METADATA you need to clone both:

```
Pkg.clone("https://github.com/Riscure/Jlsca")
```

and then:

```
Pkg.clone("https://github.com/ceesb/Jldfa")
```

Check `tests/dfa-aes-tests.jl` on howto use for AES and `test/dfa-des-tests.jl` on how to use for DES. The tests read faulty outputs from a text file, so should be easy to adopt to your needs.
