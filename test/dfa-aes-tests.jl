# This file is part of Jldfa, license is GPLv3, see https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Author: Cees-Bart Breunesse

using Jlsca:Aes
using Jldfa

using Base.Test

function corrupt(label,state)
    if label == "r8.s_box"
        # single byte fault before 2nd to last MC
        state[rand(1:16)] ⊻= rand(UInt8)
    end

    return state
end

function createdump(nrfaults)
    key = rand(UInt8, 16)
    input = rand(UInt8, 16)
    expkey = Aes.KeyExpansion(key, 10, 4)
    correct = Aes.Cipher(input,expkey)

    (path,io) = mktemp()

    print("dumping into $path\n")

    # first is correct
    write(io, bytes2hex(Aes.Cipher(input,expkey)), "\n")

    for i in 1:nrfaults        
        write(io, bytes2hex(Aes.Cipher(input,expkey,corrupt)), "\n")
    end

    close(io)

    return key,path
end

function test()
    key,path = createdump(50)

    a = AesDfaState()
    
    io = open(path,"r")
    correct = hex2bytes(readline(io))

    while !eof(io)
        faulty = hex2bytes(readline(io))
        update!(a,faulty,correct)
    end

    close(io)

    recoveredrk = getKey(a)
    recoveredrk = Aes.ShiftRows(recoveredrk)
    recoveredkey = Aes.KeyExpansionBackwards(vec(recoveredrk), 10, 4)[1:16]

    print("known key:           $(bytes2hex(key))\n")
    print("recovered key:       $(bytes2hex(recoveredkey))\n")
    @test key == recoveredkey
    rm(path)
end

test()
