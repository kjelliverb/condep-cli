properties {
	$pwd = Split-Path $psake.build_script_file	
	$build_directory  = "$pwd\output\condep-cli"
	$configuration = "Release"
	$preString = "-beta"
	$releaseNotes = ""
	$nuget = "$pwd\..\tools\nuget.exe"
}
 
include .\..\tools\psake_ext.ps1

function GetNugetAssemblyVersion($assemblyPath) {
	$versionInfo = Get-Item $assemblyPath | % versioninfo

	return "$($versionInfo.FileMajorPart).$($versionInfo.FileMinorPart).$($versionInfo.FileBuildPart)$preString"
}

task default -depends Build-All, Pack-All
task ci -depends Build-All, Pack-All

task Pack-All -depends Pack-ConDep-Console
task Build-All -depends Clean, Build, Create-BuildSpec-ConDep-Console

task Build {
	Exec { msbuild "$pwd\..\src\condep-cli.sln" /t:Build /p:Configuration=$configuration /p:OutDir=$build_directory /p:GenerateProjectSpecificOutputFolder=true}
}

task Clean {
	Write-Host "Cleaning Build output"  -ForegroundColor Green
	Remove-Item $build_directory -Force -Recurse -ErrorAction SilentlyContinue
}

task Create-BuildSpec-ConDep-Console {
	Generate-Nuspec-File `
		-file "$build_directory\condep.console.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\ConDep.Console\ConDep.exe) `
		-id "ConDep" `
		-title "ConDep" `
		-licenseUrl "http://www.con-dep.net/license/" `
		-projectUrl "http://www.con-dep.net/" `
		-description "ConDep is a highly extendable Domain Specific Language for Continuous Deployment, Continuous Delivery and Infrastructure as Code on Windows." `
		-iconUrl "https://raw.github.com/condep/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote aws azure" `
		-dependencies @(
			@{ Name="ConDep.Dsl"; Version="[4.0.0$preString,5)"},
			@{ Name="ConDep.Dsl.Operations"; Version="[3.2.0$preString,4)"},
			@{ Name="ConDep.Dsl.Remote.Helpers"; Version="[3.1.0$preString,4)"},
			@{ Name="ConDep.Node"; Version="[4.0.0$preString,5)"},
			@{ Name="ConDep.WebQ.Client"; Version="[2.0.0,3)"},
			@{ Name="NDesk.Options"; Version="0.2.1"},
			@{ Name="SlowCheetah.Tasks.Unofficial"; Version="1.0.0"}
			@{ Name="YamlDotNet"; Version="[3.5.1]"}
		) `
		-files @(
			@{ Path="ConDep.Console\ConDep.exe"; Target="lib/net40"}
		)
}

task Pack-ConDep-Console {
	Exec { & $nuget pack "$build_directory\condep.console.nuspec" -OutputDirectory "$build_directory" }
}