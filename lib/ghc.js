'use babel'

const child_process = require('child_process');
const path = require('path')
const Ghci = require('./ghci')
const ghciPathProperty = 'tidalcycles.ghciPath'

export default class Ghc {

  static interactive() {
    return new Ghci(
      child_process.spawn(Ghc.commandPath('ghci'), [], { shell: true })
    )
  }

  static browseTidal(callback) {
    let ghciPath = Ghc.commandPath('ghci')
    child_process.exec(`echo ":browse Sound.Tidal.Context" | ${ghciPath}`,
      (error, stdout) => {
        if (error) {
          console.error(`exec error: ${error}`);
          return;
        }
        callback(stdout)
    })
  }

  static commandPath(name) {
    let propertyValue = Ghc.ghciPathProperty()
    if (propertyValue) {
      return path.basename(propertyValue) === 'ghci'
        ? path.join(path.parse(propertyValue).dir, name)
        : path.join(propertyValue, name)
    } else {
      return name
    }
  }

  static tidalDataDir() {
    try {
      let dataDir = child_process
        .execSync(`${Ghc.commandPath('ghc-pkg')} field tidal data-dir`)
        .toString().trim()

      return dataDir.substring(dataDir.indexOf(' ') + 1)
    } catch (err) {
      return err
    }

  }

  static ghciPathProperty() {
    return atom.config.get(ghciPathProperty)
  }

}