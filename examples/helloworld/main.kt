package examples.helloworld

import com.google.common.base.Joiner
import examples.helloworld.SoyMilk

fun main(args : Array<String>) {
	println(Joiner.on(' ').join(arrayOf("I", "am", "Kotlin!", "......")))
	println(Joiner.on(' ').join(arrayOf("...", "But", "what", "is", "soy", "milk?")))
	println(SoyMilk())
}
