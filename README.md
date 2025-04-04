# Design Automation signer

[![Design-Automation](https://img.shields.io/badge/Design%20Automation-v3-green.svg)](http://developer.autodesk.com/)
![.Node.js](https://img.shields.io/badge/Node.js-blue.svg)

[![License](http://img.shields.io/:license-MIT-blue.svg)](http://opensource.org/licenses/MIT)

# Description

This is a utility to sign the parts of the workitem request message with the right algorithm and parameters.

## Prerequisites

[node.js](https://nodejs.org/)

## Usage
Display available commands
```bash
node signer.js
```

- Generate a public/private key pair.

```bash
node signer.js generate mykey.json
```

- Export the public key into a json file.

```bash
node signer.js export mykey.json mypublickey.json
```

- Upload public key using PATCH forgeapps/me API (see https://forge.autodesk.com/en/docs/design-automation/v3/reference/http/forgeapps-id-PATCH/). 

```bash
curl forgeapps/me -x PATCH `{'publicKey' : <contents of mypublickey.json>}`
```

- Generate digital signature for the `activityId` that it wants to call.

```bash
node signer.js sign mykey.json <ForgeAppNickNameOrId>.PlotToPdf+<Alias>
```
## Test

- create `setenv.bat`

```
set CLIENT_ID=<<YOUR CLIENT ID FROM DEVELOPER PORTAL>>
set CLIENT_SECRET=<<YOUR CLIENT SECRET>>
```

- Create a basic activity, lets name our activity `HelloWorld` with alias `prod`.  Note I'm using `adesk` as forgeapp nickname.
  
  - ```bash
    {
        "commandLine": "$(engine.path)\\accoreconsole.exe /s \"$(settings[script].path)\"",
        "engine": "Autodesk.AutoCAD+24",
        "settings": {
            "script": "(print \"Hello World!\")\n"
        },
        "description": "Send String To Execute Test",
        "id": "{{ _.activityId }}"
    }
    ```
  
  - ```bash
    {
        "version": 1,
        "id": "{{ _.alias }}"
    }
    ```

- Test with scripts -

```batch
pwsh Test\createActivity.ps1
node signer.js generate mykey.json
node signer.js export mykey.json mypublickey.json
pwsh Test\patchPublicKey.ps1
node signer.js sign mykey.json adesk.HelloWorld+prod > sign.txt
pwsh Test\workitem.ps1
```

## License

This sample is licensed under the terms of the [MIT License](http://opensource.org/licenses/MIT). Please see the [LICENSE](LICENSE) file for full details.
