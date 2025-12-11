command_exists() {
  command -v $1 >/dev/null 2>&1
}



download_fabric() {
  local mc_version=$1
  local loader_version=$2
  installer_version="1.1.0"

  url="https://meta.fabricmc.net/v2/versions/loader/$mc_version/$loader_version/$installer_version/server/jar"

  gum spin --title="Downloading Fabric $1" -- curl -OJ $url
}

fabric() {
  mc_version=$(
    gum spin --title="Getting minecraft versions" -- curl -s https://meta.fabricmc.net/v2/versions/game |
    jq -r ".[].version" | 
    gum filter --fuzzy --placeholder="Find version" --indicator="*" --indicator.bold=1
  )

  
  loader_version=$(
    gum spin --title="Getting loader versions" -- curl -s https://meta.fabricmc.net/v2/versions/loader |
    jq -r ".[].version" | 
    gum filter --fuzzy --placeholder="Find version" --indicator="*" --indicator.bold=1
  )

  download_fabric $mc_version $loader_version
}


check_dependencies() {
  if ! command_exists java; then
    echo "Java is not installed"
    exit 1
  fi

  if ! command_exists gum; then
    echo "Gum is not installed"
    exit 1
  fi
}

generate_launch_script() {
  local executable=$1
  local ram_size=$2
  echo '
if [ -z $(ls | grep eula.txt) ]; then 
  echo "eula=True" > eula.txt
fi 
 java -Xmx'$ram_size'G -jar '$executable' nogui
  ' > launch.sh
}

setup() {
  ram_size=$(echo 2 | gum input --placeholder="GB" --prompt="Allocate memory: ")

  generate_launch_script $(ls) $ram_size
  chmod +x ./launch.sh

  echo "Launch with ./launch.sh"
}

install() {
  path=$1

  if [ -z $path ]; then
    path=$(gum input --placeholder="Enter path (Blank for this folder)")
    if [ -z $path ]; then path="."; fi
  fi

  mkdir -p $1
  cd $path


  if [ -n "$(ls)" ]; then
    if ! gum confirm "The targeted directory ($path) is not empty" --affirmative="Erase and Continue" --negative="Stop" ; then
      exit 1
    fi
  fi

  rm *

  fabric
  
  setup
}

install $@
