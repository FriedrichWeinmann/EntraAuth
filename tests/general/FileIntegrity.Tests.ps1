﻿$moduleRoot = (Resolve-Path "$global:testroot\..").Path

. "$global:testroot\general\FileIntegrity.Exceptions.ps1"

Describe "Verifying integrity of module files" {
	BeforeAll {
		function Get-FileEncoding {
			<#
			.SYNOPSIS
				Tests a file for encoding.
			
			.DESCRIPTION
				Tests a file for encoding.
			
			.PARAMETER Path
				The file to test
		#>
			[CmdletBinding()]
			param (
				[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
				[Alias('FullName')]
				[string]
				$Path
			)
			
			if ($PSVersionTable.PSVersion.Major -lt 6) {
				[byte[]]$byte = Get-Content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
			}
			else {
				[byte[]]$byte = Get-Content -AsByteStream -ReadCount 4 -TotalCount 4 -Path $Path
			}
			
			if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf) { 'UTF8 BOM' }
			elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff) { 'Unicode' }
			elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff) { 'UTF32' }
			elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76) { 'UTF7' }
			else { 'Unknown' }
		}
	}

	Context "Validating PS1 Script files" {
		$allFiles = Get-ChildItem -Path $moduleRoot -Recurse | Where-Object Name -Like "*.ps1" | Where-Object FullName -NotLike "$moduleRoot\tests\*"
		
		foreach ($file in $allFiles) {
			$name = $file.FullName.Replace("$moduleRoot\", '')
			
			It "[$name] Should have UTF8 encoding with Byte Order Mark" -TestCases @{ file = $file } {
				Get-FileEncoding -Path $file.FullName | Should -Be 'UTF8 BOM'
			}
			
			It "[$name] Should have no trailing space" -TestCases @{ file = $file } {
				($file | Select-String "\s$" | Where-Object { $_.Line.Trim().Length -gt 0 }).LineNumber | Should -BeNullOrEmpty
			}
			
			if ($file.Name -notin $global:IgnoreSyntaxErrors) {
				$tokens = $null
				$parseErrors = $null
				$null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
			
				It "[$name] Should have no syntax errors" -TestCases @{ parseErrors = $parseErrors } {
					$parseErrors | Should -BeNullOrEmpty
				}
			}
			
			foreach ($command in $global:BannedCommands) {
				if ($global:MayContainCommand["$command"] -notcontains $file.Name) {
					It "[$name] Should not use $command" -TestCases @{ tokens = $tokens; command = $command } {
						$tokens | Where-Object Text -EQ $command | Should -BeNullOrEmpty
					}
				}
			}
		}
	}
	
	Context "Validating help.txt help files" {
		$allFiles = Get-ChildItem -Path $moduleRoot -Recurse | Where-Object Name -Like "*.help.txt" | Where-Object FullName -NotLike "$moduleRoot\tests\*"
		
		foreach ($file in $allFiles) {
			$name = $file.FullName.Replace("$moduleRoot\", '')
			
			It "[$name] Should have UTF8 encoding" -TestCases @{ file = $file } {
				Get-FileEncoding -Path $file.FullName | Should -Be 'UTF8 BOM'
			}
			
			It "[$name] Should have no trailing space" -TestCases @{ file = $file } {
				($file | Select-String "\s$" | Where-Object { $_.Line.Trim().Length -gt 0 } | Measure-Object).Count | Should -Be 0
			}
		}
	}
}