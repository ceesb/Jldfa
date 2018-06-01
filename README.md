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

# AES example

Needs a text file with a correct output in hex on the first line, and faulty outputs on subsequent lines.

```
cat > myfaultyoutputs.txt << EOF
7eaa71a0f676c8dad2686874c850121e
093ce71ae62ba832c47ef13bd9841b47
ead115974ac39ed1da9f58ee7e766f9a
502e848349e70a1663b9887294b1422e
cbe1ea9bc4d80c6a5f02edde50be39b6
fba5ff33a198bc0ae4d4a594bfe4e06e
931572c1b2cb769425abd818e6cec1c3
312a821d8493f81b896bab21903db23c
a93374578563d4c726c4c8cc96de1964
6da5e623893b392b97eb9a7723e2e6a7
f69077e76264598933e8e40b3b7b8dbf
bee180e290df25bcbc4272f85dd10c54
110de3415754e618f087206f04529d5a
2fb481d1cf0fc3ef153eeb8e80b92b95
37f9b4fb26fb51f354ce637c0bfbdc30
48138cb7c1b86f1105946121cf350694
92c2413c9c61a7b167c286038d0f54a8
49952faa609ffffe48e2a3841df7694a
ea85dd5c658921ee5000694ab1e95d2f
EOF
```
Then, run this in Julia.
```
using Jlsca:Aes
using Jldfa

a = AesDfaState()

io = open("myfaultyoutputs.txt","r")
correct = hex2bytes(readline(io))

while !eof(io)
    faulty = hex2bytes(readline(io))
    update!(a,faulty,correct)
end

close(io)

recoveredrk = getKey(a)
recoveredrk = Aes.ShiftRows(recoveredrk)
recoveredkey = Aes.KeyExpansionBackwards(vec(recoveredrk), 10, 4)[1:16]

print("recovered key:       $(bytes2hex(recoveredkey))\n")
```
Should print "2b0b097b0538051017b276ff8f7313f4". Take a look at `tests/dfa-aes-tests.jl` if you want to see how to generate these faults.

# DES example

Take a look at  `test/dfa-des-tests.jl`. Code is a bit more involved since it recovers two round keys.
