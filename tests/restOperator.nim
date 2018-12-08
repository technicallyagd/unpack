import unpack

let mamaHen = @[3, 4, 5, 6, 7]

[a, b, *sneakyFox] <- mamaHen

# is expanded into:
# let
#   a = mamaHen[0]
#   b = mamaHen[1]
#   sneakyFox = mamaHen[2..^1]

assert(sneakyFox == @[5, 6, 7])

[*sloppySavior, e] <- sneakyFox

assert(sloppySavior == @[5, 6])

# Perhaps the variable naming may be a bit mis-leading,
# since mamaHen[x..y] creates a new sequence and copy the slice into it,
# so rather than stealing, the sneakyFox actually cloned(?) whatever mamaHen had with her

# You can use *_ to skip the beginning
[*_, pickyFox] <- mamaHen

assert(pickyFox == 7)

[f, g, *randomFox, _, h] <- mamaHen

assert([f, g, h] == [3, 4, 7])

assert(randomFox == @[5])
