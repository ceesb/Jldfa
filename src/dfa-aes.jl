# This file is part of Jldfa, license is GPLv3, see https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Author: Cees-Bart Breunesse

using Jlsca.Aes
using Base.Test

export AesDfaState

type AesDfaState
    scores::Array{Int,3}

    function AesDfaState()
        new(zeros(Int, 4,4,256))
    end
end

export update!

function update!(state::AesDfaState,col::Int,faultycol::Vector{UInt8},correctcol::Vector{UInt8})
    for z in collect(UInt8,1:255)
        for zrow in 1:4
            zstate = zeros(UInt8, 4)
            zstate[zrow] = z
            zmcol = Aes.MixColumn(zstate)
            candy = zeros(UInt8,4)
            valid = falses(4)
            for yrow in 1:4
                for y in collect(UInt8,0:255)
                    a = faultycol[yrow] ⊻ correctcol[yrow]
                    b = Aes.sbox[y+1] ⊻ Aes.sbox[(y ⊻ zmcol[yrow])+1]
                    if a == b
                        candy[yrow] = y
                        valid[yrow] = true
                        break
                    end
                end
            end

            if !(false in valid)
                for yrow in 1:4
                    y = candy[yrow]
                    kb1 = (Aes.sbox[y+1] ⊻ correctcol[yrow])
                    kb2 = (Aes.sbox[(y ⊻ zmcol[yrow])+1] ⊻ correctcol[yrow])
                    @test kb1 != kb2
                    state.scores[yrow,col,kb1+1] += 1
                    state.scores[yrow,col,kb2+1] += 1
                end
            end
        end
    end
end

function update!(a::AesDfaState,faulty::Vector{UInt8},correct::Vector{UInt8})
    faultyM = reshape(faulty, (4,4))   
    correctM = reshape(correct, (4,4))

    faultyM = Aes.InvShiftRows(faultyM)
    correctM = Aes.InvShiftRows(correctM)

    if faultyM[:,4] != correctM[:,4]
        col = 4
        update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end
    if faultyM[:,3] != correctM[:,3]
        col = 3
        update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end
    if faultyM[:,2] != correctM[:,2]
        col = 2
        update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end
    if faultyM[:,1] != correctM[:,1]
        col = 1
        update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end

    return true
end

export getKey

function getKey(a::AesDfaState)
    (vals,indxs) = findmax(a.scores, 3)
    recoveredrk = zeros(UInt8,(4,4))
    for i in indxs
        (r,c,p) = ind2sub(a.scores, i)
        recoveredrk[r,c] = UInt8(p-1)
    end
    return recoveredrk
end

