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

# It's okay to take the middle chunk too.
[f, g, *randomFox, _, h] <- mamaHen

assert([f, g, h] == [3, 4, 7])
assert(randomFox == @[5])

# Due to restriction from nim's grammar, `*` following `var`
# is not allowed. Adding `_ as` before it is the current hack I chose to bypass this.
[var _ as *boldFox, i, j] <- mamaHen

assert([i, j] == [6, 7])
assert(boldFox == @[3, 4, 5])

# They are indeed created with var.
i = 12
boldFox[2] = 123

assert(i == 12)
assert(boldFox == @[3, 4, 123])

# Works with nested unpack as well.

let tisMad = @[@[@[1, 2, 3], @[4, 5]], @[@[6], @[7, 8, 9, 10]]]

[var [[z, *y], [_, x]], [[w], [_, *v, u]]] <- tisMad

assert([z, x, w, u] == [1, 5, 6, 10])
assert(y == @[2, 3])
assert(v == @[8, 9])
