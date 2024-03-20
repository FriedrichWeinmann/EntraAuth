function ConvertTo-SignedString {
<#
	.SYNOPSIS
		Signs input string with the offered certificate.
	
	.DESCRIPTION
		Signs input string with the offered certificate.
	
	.PARAMETER Text
		The text to sign.
	
	.PARAMETER Certificate
		The certificate to sign with.
		The Private Key must be available.
	
	.PARAMETER Padding
		What RSA Signature padding to use.
		Defaults to Pkcs1
	
	.PARAMETER Algorithm
		What algorithm to use for signing.
		Defaults to SHA256
	
	.PARAMETER Encoding
		The encoding to use for transforming the text to bytes before signing it.
		Defaults to UTF8
	
	.EXAMPLE
		PS C:\> ConvertTo-SignedString -Text $token
	
		Signs the specified token
#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]]
		$Text,
		
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate,
		
		[Security.Cryptography.RSASignaturePadding]
		$Padding = [Security.Cryptography.RSASignaturePadding]::Pkcs1,
		
		[Security.Cryptography.HashAlgorithmName]
		$Algorithm = [Security.Cryptography.HashAlgorithmName]::SHA256,
		
		[System.Text.Encoding]
		$Encoding = [System.Text.Encoding]::UTF8
	)
	
	begin {
		$privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
	}
	process {
		foreach ($entry in $Text) {
			$inBytes = $Encoding.GetBytes($entry)
			$outBytes = $privateKey.SignData($inBytes, $Algorithm, $Padding)
			[convert]::ToBase64String($outBytes)
		}
	}
}