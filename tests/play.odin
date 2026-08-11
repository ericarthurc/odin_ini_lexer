package play

import "core:fmt"

src := `burge=taco`

main :: proc() {
	fmt.println(src[1:1])
}
