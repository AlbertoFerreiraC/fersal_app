import com.android.build.api.variant.LibraryAndroidComponentsExtension

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
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
    // Esta versión del visor fija API 31, incompatible con sus dependencias.
    // Ajustar su SDK al de la app sin modificar el paquete en la caché de Pub.
    if (name == "syncfusion_flutter_pdfviewer") {
        plugins.withId("com.android.library") {
            project.extensions.configure<LibraryAndroidComponentsExtension> {
                finalizeDsl { library -> library.compileSdk = 36 }
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
