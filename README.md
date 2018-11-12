# What is it?

This is a small library for doing DFA (differental fault attacks). Currently supports fault attacks on AES and DES. The library uses Jlsca, my other toy project, and since it's not part of METADATA you need to clone both:

```
using Pkg; 
Pkg.add(PackageSpec(url="https://github.com/Riscure/Jlsca"))
```

and then:

```
Pkg.add(PackageSpec(url="https://github.com/ceesb/Jldfa"))
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

io = open(ARGS[1],"r")
correct = hex2bytes(readline(io))

while !eof(io)
    faulty = hex2bytes(readline(io))
    update!(a,faulty,correct)
end

close(io)

recoveredrk = getKey(a)
recoveredrk = Aes.ShiftRows(recoveredrk)
recoveredkey = Aes.KeyExpansionBackwards(vec(recoveredrk), 10, 4)[1:16]

print("recovered rk:         $(bytes2hex(recoveredrk))\n")
print("recovered aes128 key: $(bytes2hex(recoveredkey))\n")


(rows,cols,candidates) = size(a.scores)

for row in 1:rows
        for col in 1:cols
                sorted = sortperm(a.scores[row,col,:], rev=true)
                print("row $row, col $col\n") 
                for i in 1:5
                        idx = sorted[i]
                        val = a.scores[row,col,idx]
                        print("\trank: $i, score $(val), kb 0x$(string(idx-1, base=16)),\n")
                end
                print("\n")
        end
end

```
Should print this:
```
recovered rk:         ff28d15cae2bb5d9e68a0e760b08c2c6
recovered aes128 key: 2b0b097b0538051017b276ff8f7313f4
row 1, col 1
        rank: 1, score 24, kb 0xff
        rank: 2, score 15, kb 0x19
        rank: 3, score 14, kb 0x3e
        rank: 4, score 14, kb 0x56
        rank: 5, score 14, kb 0xe5

row 1, col 2
        rank: 1, score 26, kb 0xae
        rank: 2, score 17, kb 0x4e
        rank: 3, score 16, kb 0x41
        rank: 4, score 15, kb 0x40
        rank: 5, score 15, kb 0xb7

row 1, col 3
        rank: 1, score 27, kb 0xe6
        rank: 2, score 17, kb 0x57
        rank: 3, score 17, kb 0xbc
        rank: 4, score 16, kb 0xaa
        rank: 5, score 16, kb 0xff

row 1, col 4
        rank: 1, score 24, kb 0xb
        rank: 2, score 17, kb 0xe3
        rank: 3, score 16, kb 0x1a
        rank: 4, score 15, kb 0x4
        rank: 5, score 15, kb 0x5a

row 2, col 1
        rank: 1, score 26, kb 0x8
        rank: 2, score 17, kb 0xb
        rank: 3, score 15, kb 0x48
        rank: 4, score 15, kb 0xd4
        rank: 5, score 14, kb 0x26

row 2, col 2
        rank: 1, score 23, kb 0x28
        rank: 2, score 18, kb 0x1d
        rank: 3, score 17, kb 0x89
        rank: 4, score 16, kb 0x92
        rank: 5, score 16, kb 0x9f

row 2, col 3
        rank: 1, score 25, kb 0x2b
        rank: 2, score 17, kb 0x79
        rank: 3, score 16, kb 0x8b
        rank: 4, score 16, kb 0xc9
        rank: 5, score 16, kb 0xe2

row 2, col 4
        rank: 1, score 24, kb 0x8a
        rank: 2, score 19, kb 0x9c
        rank: 3, score 17, kb 0x71
        rank: 4, score 16, kb 0xbf
        rank: 5, score 16, kb 0xee

row 3, col 1
        rank: 1, score 23, kb 0xe
        rank: 2, score 16, kb 0xc
        rank: 3, score 16, kb 0x26
        rank: 4, score 16, kb 0x94
        rank: 5, score 16, kb 0xd2

row 3, col 2
        rank: 1, score 24, kb 0xc2
        rank: 2, score 18, kb 0x64
        rank: 3, score 16, kb 0xc
        rank: 4, score 16, kb 0x15
        rank: 5, score 16, kb 0x79

row 3, col 3
        rank: 1, score 22, kb 0xd1
        rank: 2, score 19, kb 0x2b
        rank: 3, score 18, kb 0x25
        rank: 4, score 18, kb 0xea
        rank: 5, score 16, kb 0x2d

row 3, col 4
        rank: 1, score 23, kb 0xb5
        rank: 2, score 20, kb 0xe
        rank: 3, score 18, kb 0xb2
        rank: 4, score 18, kb 0xb8
        rank: 5, score 17, kb 0x91

row 4, col 1
        rank: 1, score 24, kb 0xd9
        rank: 2, score 18, kb 0x18
        rank: 3, score 16, kb 0x20
        rank: 4, score 15, kb 0x15
        rank: 5, score 15, kb 0x65

row 4, col 2
        rank: 1, score 22, kb 0x76
        rank: 2, score 17, kb 0xa2
        rank: 3, score 16, kb 0xee
        rank: 4, score 15, kb 0x4a
        rank: 5, score 15, kb 0x9f

row 4, col 3
        rank: 1, score 30, kb 0xc6
        rank: 2, score 18, kb 0xfd
        rank: 3, score 17, kb 0x85
        rank: 4, score 16, kb 0xf8
        rank: 5, score 15, kb 0x73

row 4, col 4
        rank: 1, score 24, kb 0x5c
        rank: 2, score 18, kb 0x18
        rank: 3, score 17, kb 0x37
        rank: 4, score 15, kb 0x12
        rank: 5, score 15, kb 0x30

```
Take a look at `tests/dfa-aes-tests.jl` if you want to see how to generate these faults.

# DES example

Take a look at  `test/dfa-des-tests.jl`. Code is a bit more involved since it recovers two round keys.
