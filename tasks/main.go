package main

import (
	"fmt"

	//if you imports this with .  you do not have to repeat overflow everywhere
	. "github.com/bjartek/overflow/v2"
	"github.com/fatih/color"
)

// ReadFile reads a text file and returns an array of paragraphs

func main() {
	o := Overflow(
		WithGlobalPrintOptions(),
	//	WithNetwork("mainnet"),
	)

	fmt.Println("Testing Contract")

	color.Blue("PinPin Contract testing")

	/* 	o.Tx("mint",
		WithSigner("pinpin"),
	).Print() */

}
