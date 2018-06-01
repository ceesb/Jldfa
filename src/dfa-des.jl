# This file is part of Jldfa, license is GPLv3, see https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Author: Cees-Bart Breunesse

using Jlsca.Trs
using Jlsca.Des
using Base.Test

const left = 1:32
const right = 33:64

export DesDfaState

type DesDfaState
    scores::Array{Int,2}

    function DesDfaState()
        new(zeros(Int, 8,64))
    end
end

export update!

function update!(state::DesDfaState,faultyI::BitVector,correctI::BitVector)
    fout = invP(correctI[left] .⊻ faultyI[left])
    aE = E(correctI[right])
    bE = E(faultyI[right])

    for sbox in 1:8
        i = (sbox-1)*6
        o = (sbox-1)*4
        c = fout[o+1:o+4]
        if true in c
            for k in 0:63
                kB = toBits(k,6)
                a = Sbox(aE[i+1:i+6] .⊻ kB,Sbox(sbox))
                b = Sbox(bE[i+1:i+6] .⊻ kB,Sbox(sbox))
                if a .⊻ b == c
                    state.scores[sbox,k+1] += 1
                end
            end
        end
    end
end

export getKey

function getKey(a::DesDfaState)
    rk = zeros(UInt8,8)
    (vals,indxs) = findmax(a.scores, 2)
    for i in indxs
        (sbox,p) = ind2sub(a.scores, i)
        rk[sbox] = UInt8(p-1)
    end
    return rk
end

