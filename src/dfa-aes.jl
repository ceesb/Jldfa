# This file is part of Jldfa, license is GPLv3, see https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Author: Cees-Bart Breunesse

using Jlsca.Aes

export AesDfaState

mutable struct AesDfaState
    scores::Array{Int,3}
    cnt::Int

    function AesDfaState()
        new(zeros(Int, 4,4,256), 0)
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
                    @assert kb1 != kb2
                    state.scores[yrow,col,kb1+1] += 1
                    state.scores[yrow,col,kb2+1] += 1
                end
            end
        end
    end
end

function update!(a::AesDfaState,faulty::Vector{UInt8},correct::Vector{UInt8}; single_column=false)
    faultyM = reshape(faulty, (4,4))   
    correctM = reshape(correct, (4,4))

    faultyM = Aes.InvShiftRows(faultyM)
    correctM = Aes.InvShiftRows(correctM)


    cols = falses(4)

    if faultyM[:,4] != correctM[:,4]
        cols[4] = true
        # update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end
    if faultyM[:,3] != correctM[:,3]
        cols[3] = true
        # update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end
    if faultyM[:,2] != correctM[:,2]
        cols[2] = true
        # update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end
    if faultyM[:,1] != correctM[:,1]
        cols[1] = true
        # update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
    end


    if single_column
        if count(x -> x == true, cols) > 1
            return false
        else
            a.cnt += 1
            col = findfirst(x -> x == true, cols)
            update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
        end
    else
        a.cnt += 1
        for col in eachindex(cols)
            if cols[col]
                update!(a,col,vec(faultyM[:,col]), vec(correctM[:,col]))
            end
        end
    end

    return true
end

export getKey

function getKey(a::AesDfaState)
    (vals,indxs) = findmax(a.scores, dims=3)
    recoveredrk = zeros(UInt8,(4,4))
    ci = CartesianIndices(a.scores)
    for i in indxs
        (r,c,p) = Tuple(ci[i])
        recoveredrk[r,c] = UInt8(p-1)
    end
    return recoveredrk
end

