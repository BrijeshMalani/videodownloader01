allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://www.arthenica.com/maven")
        }
        maven {
            url = uri("https://www.jitpack.io")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    // Fix namespace issue for packages that don't have it
    val packagesNeedingNamespace = listOf("flutter_ffmpeg", "video_thumbnail")
    if (project.name in packagesNeedingNamespace) {
        project.afterEvaluate {
            val buildGradleFile = project.file("build.gradle")
            if (buildGradleFile.exists()) {
                var content = buildGradleFile.readText()
                if (!content.contains("namespace")) {
                    // Try to get namespace from AndroidManifest
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestContent = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                        if (packageMatch != null) {
                            val namespace = packageMatch.groupValues[1]
                            // Add namespace to android block
                            content = content.replace(
                                Regex("android\\s*\\{"),
                                "android {\n    namespace = \"$namespace\""
                            )
                            buildGradleFile.writeText(content)
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
