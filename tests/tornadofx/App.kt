import tornadofx.App
import tornadofx.View
import tornadofx.launch
import tornadofx.vbox

class MyView: View() {
        override val root = vbox()
}

class MyApp: App(MyView::class)

fun main(args: Array<String>) = launch<MyApp>(args)
