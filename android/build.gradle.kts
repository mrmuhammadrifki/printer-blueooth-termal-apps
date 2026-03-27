allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Workaround for blue_thermal_printer namespace issue in AGP 8
subprojects {
    val subproject = this
    if (subproject.name == "blue_thermal_printer") {
        if (subproject.state.executed) {
            fixNamespace(subproject)
        } else {
            subproject.afterEvaluate {
                fixNamespace(subproject)
            }
        }
    }
}

fun fixNamespace(p: Project) {
    try {
        val android = p.extensions.findByName("android")
        if (android != null) {
            val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
            setNamespace.invoke(android, "id.kakzaki.blue_thermal_printer")
            println("Fixed namespace for blue_thermal_printer")
        } else {
             println("Android extension not found for ${p.name}")
        }
    } catch (e: Exception) {
        println("Failed to fix namespace: $e")
    }
}
