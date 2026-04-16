function binaryIndex = grayToBinary(grayIndex)
binaryIndex = grayIndex;
shifted = floor(grayIndex / 2);
while any(shifted > 0)
    binaryIndex = bitxor(binaryIndex, shifted);
    shifted = floor(shifted / 2);
end
end
