# This file is part of Jldfa, license is GPLv3, see https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Author: Cees-Bart Breunesse

using Jlsca.Des
using Jldfa

using Test

const left = 1:32
const right = 33:64

pretty(a::BitVector) = reduce(*,[i == 1 ? "1" : "0" for i in a])

function corrupt(label,state,roundlabel="r16.start",biterrorsl=8,biterrorsr=8)
    if label == roundlabel
        before = state[:]
        for bit in 1:biterrorsr
            idx = rand(0:31)
            bit = state[right[1]+idx]
            state[right[1]+idx] = !bit 
        end
        for bit in 1:biterrorsl
            idx = rand(0:31)
            bit = state[left[1]+idx]
            state[left[1]+idx] = !bit 
        end
    end

    return state
end

function createdump(nrfaults,key,roundlabel)
    input = rand(UInt8, 8)
    expkey = Des.KeyExpansion(key)
    correct = Des.Cipher(input,expkey)

    (path,io) = mktemp()

    print("dumping faulty $roundlabel into $path\n")

    # first is correct
    write(io, bytes2hex(Des.Cipher(input,expkey)), "\n")

    for i in 1:nrfaults        
        write(io, bytes2hex(Des.Cipher(input,expkey,(x,y) -> corrupt(x,y,roundlabel))), "\n")
    end

    close(io)

    return path
end

function test()
    key = map(x -> x & 0xfe, rand(UInt8, 8))
    pathrk16 = createdump(100,key,"r16.start")
    pathrk15 = createdump(100,key,"r15.start")

    a = DesDfaState()
    
    io = open(pathrk16,"r")
    correct = hex2bytes(readline(io))
    correctB = toBits(correct)
    correctI = IP(correctB)

    while !eof(io)
        faulty = hex2bytes(readline(io))
        faultyB = toBits(faulty)
        faultyI = IP(faultyB)
        update!(a,faultyI,correctI)
    end

    close(io)

    recoveredrk16 = getKey(a)

    expkey = Des.KeyExpansion(key)
    rk15 = toSixbits(getK(expkey,15))
    rk16 = toSixbits(getK(expkey,16))

    print("known rk16:           $(bytes2hex(rk16))\n")
    print("recovered rk16:       $(bytes2hex(recoveredrk16))\n")
    @test rk16 == recoveredrk16

    a = DesDfaState()

    io = open(pathrk15,"r")
    correct = hex2bytes(readline(io))
    correctB = toBits(correct)
    correctI = IP(correctB)
    fout = Des.f(correctI[right],toBits(recoveredrk16,6))
    correctI[1:64] = [correctI[right]; fout .⊻ correctI[left]]

    while !eof(io)
        faulty = hex2bytes(readline(io))
        faultyB = toBits(faulty)
        faultyI = IP(faultyB)
        fout = Des.f(faultyI[right],toBits(recoveredrk16,6))
        faultyI[1:64] = [faultyI[right]; fout .⊻ faultyI[left]]

        update!(a,faultyI,correctI)
    end

    close(io)

    recoveredrk15 = getKey(a)

    print("known rk15:           $(bytes2hex(rk15))\n")
    print("recovered rk15:       $(bytes2hex(recoveredrk15))\n")
    @test rk15 == recoveredrk15

    recoveredkey = Des.KeyExpansionBackwards(toBits(recoveredrk16,6),16,toBits(recoveredrk15,6),15)
    recoveredkey = map(x -> x & 0xfe, recoveredkey)

    print("known key:            $(bytes2hex(key))\n")
    print("recovered key:        $(bytes2hex(recoveredkey))\n")
    @test  key == recoveredkey

    rm(pathrk16)
    rm(pathrk15)
end

test()
