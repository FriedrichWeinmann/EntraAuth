function Resolve-Certificate {
	<#
	.SYNOPSIS
		Helper function to resolve certificate input.
	
	.DESCRIPTION
		Helper function to resolve certificate input.
		This function expects the full $PSBoundParameters from the calling command and will (in this order) look for these parameter names:

		+ Certificate: A full X509Certificate2 object with private key
		+ CertificateThumbprint: The thumbprint of a certificate to use. Will look first in the user store, then the machine store for it.
		+ CertificateName: The subject of the certificate to look for. Will look first in the user store, then the machine store for it. Will select the certificate with the longest expiration period.
		+ CertificatePath: Path to a PFX file to load. Also expects a CertificatePassword parameter to unlock the file.
	
	.PARAMETER BoundParameters
		The $PSBoundParameter variable of the caller to simplify passthrough.
		See Description for more details on what the command expects,
	
	.EXAMPLE
		PS C:\> $certificateObject = Resolve-Certificate -BoundParameters $PSBoundParameters

		Resolves the certificate based on the parameters provided to the calling command.
	#>
	[OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
	[CmdletBinding()]
	param (
		$BoundParameters
	)
	
	if ($BoundParameters.Certificate) { return $BoundParameters.Certificate }
	if ($BoundParameters.CertificateThumbprint) {
		if (Test-Path -Path "cert:\CurrentUser\My\$($BoundParameters.CertificateThumbprint)") {
			return Get-Item "cert:\CurrentUser\My\$($BoundParameters.CertificateThumbprint)"
		}
		if (Test-Path -Path "cert:\LocalMachine\My\$($BoundParameters.CertificateThumbprint)") {
			return Get-Item "cert:\LocalMachine\My\$($BoundParameters.CertificateThumbprint)"
		}
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Unable to find certificate with thumbprint '$($BoundParameters.CertificateThumbprint)'"
	}
	if ($BoundParameters.CertificateName) {
		if ($certificate = (Get-ChildItem 'Cert:\CurrentUser\My\').Where{ $_.Subject -eq $BoundParameters.CertificateName -and $_.HasPrivateKey }) {
			return $certificate | Sort-Object NotAfter -Descending | Select-Object -First 1
		}
		if ($certificate = (Get-ChildItem 'Cert:\LocalMachine\My\').Where{ $_.Subject -eq $BoundParameters.CertificateName -and $_.HasPrivateKey }) {
			return $certificate | Sort-Object NotAfter -Descending | Select-Object -First 1
		}
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Unable to find certificate with subject '$($BoundParameters.CertificateName)'"
	}
	if ($BoundParameters.CertificatePath) {
		try { [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($BoundParameters.CertificatePath, $BoundParameters.CertificatePassword) }
		catch {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Unable to load certificate from file '$($BoundParameters.CertificatePath)': $_" -ErrorRecord $_
		}
	}
}