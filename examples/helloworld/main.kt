package examples.helloworld

import com.google.common.base.Joiner

annotation class Feature1_2TestAnnotation(val value: Array<String>)

@Feature1_2TestAnnotation(["one", "two"])
val boom = "yaay"

fun main(args : Array<String>) {
	println(Joiner.on(' ').join(arrayOf("I", "am", "Kotlin!", "......")))
	println(Joiner.on(' ').join(arrayOf("...", "But", "what", "is", "soy", "milk?")))
	println(SoyMilk())
}
