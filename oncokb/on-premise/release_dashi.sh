# Create new folder under google drive/My Drive back up folder
# Usage -f 'Release name' -v public,internal,beta,curate,cbx -b master
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -f|--f)
    FN="$2"
    shift # past argument
    ;;
    -v|--versions)
    VERSIONS="$2"
    shift # past argument
    ;;
    -b|--branch)
    BRANCH="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

# folder name where the war files will be saved
GDRP='/release/dashi/'

## properties folder where all properties saved for different war files
GDProps='/properties'

# this is where the oncokb core repo is located
ONCOKBPATH="origin-repos/oncokb"


ONCOKB_CORE_RESOURCES_PATH="${ONCOKBPATH}/core/src/main/resources"
ONCOKB_CORE_PROPERTY_PATH="${ONCOKB_CORE_RESOURCES_PATH}/properties"
ONCOKB_WEB_RESOURCES_PATH="${ONCOKBPATH}/web/src/main/resources"
ONCOKB_FRONT_DATA_PATH="${ONCOKBPATH}/web/yo/app/data/"
now=$(date +"%m_%d_%Y_%H_%M_%S")

# create folders that do not exist before
mkdir -p ~/"$ONCOKB_CORE_RESOURCES_PATH"
mkdir -p ~/"$ONCOKB_CORE_PROPERTY_PATH"
mkdir -p ~/"$ONCOKB_WEB_RESOURCES_PATH"

if [ "$FN" == "" ]
then
    FN="All"
fi

if [ "$VERSIONS" == "" ]
then
    VERSIONS="internal,beta,curate,cbx"
fi

if [ "$BRANCH" == "" ]
then
    BRANCH="master"
fi
FN="${FN// /_}"
FN=$now"_"$FN

cd ~/"$GDRP"
mkdir "$FN"

cd ~/"$GDRP$FN";
mkdir "backup"

echo "*************** Backup war files ***************";
if [[ $VERSIONS == *"internal"* ]]
then
    scp hongxin@dashi.cbio.mskcc.org:/srv/www/oncokb-tomcat/tomcat7/webapps/internal.war ~/"$GDRP$FN/backup/"
fi
if [[ $VERSIONS == *"cbx"* ]]
then
    scp hongxin@dashi.cbio.mskcc.org:/srv/www/oncokb-tomcat/tomcat7/webapps/cbx.war ~/"$GDRP$FN/backup/"
fi
if [[ $VERSIONS == *"beta"* ]]
then
    scp hongxin@dashi.cbio.mskcc.org:/srv/www/oncokb-tomcat/tomcat7/webapps/beta.war ~/"$GDRP$FN/backup/"
fi
if [[ $VERSIONS == *"curate"* ]]
then
    scp hongxin@dashi.cbio.mskcc.org:/srv/www/oncokb-tomcat/tomcat7/webapps/curate.war ~/"$GDRP$FN/backup/"
fi
echo "*************** Done ***************";


# Create api/internal war
if [[ $VERSIONS == *"internal"* ]]
then
    echo "***************Building Internal OncoKB Instance***************";
    cd ~/"$ONCOKBPATH";
    git checkout $BRANCH;
    cp ~/"$GDProps"/dashi.internal/database.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.internal/config.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.internal/log4j.properties ~/"$ONCOKB_CORE_RESOURCES_PATH"/
    cp ~/"$GDProps"/dashi.internal/sentry.properties ~/"$ONCOKB_WEB_RESOURCES_PATH"/
    cd ~/"$ONCOKBPATH";
    mvn clean -P public -q
    cd ~/"$ONCOKBPATH";
    mvn -Dmaven.test.skip=true install -P public -q
    cp ~/"$ONCOKBPATH"/web/target/app.war ~/"$GDRP$FN"/internal.war
    echo "*************** Done ***************";
fi

# Create beta war
if [[ $VERSIONS == *"beta"* ]]
then
    echo "***************Building Beta OncoKB Instance***************";
    cd ~/"$ONCOKBPATH";
    git checkout $BRANCH;
    cp ~/"$GDProps"/dashi.beta/database.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.beta/config.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.beta/log4j.properties ~/"$ONCOKB_CORE_RESOURCES_PATH"/
    cp ~/"$GDProps"/dashi.beta/sentry.properties ~/"$ONCOKB_WEB_RESOURCES_PATH"/
    cd ~/"$ONCOKBPATH";
    mvn clean -P public -q
    cd ~/"$ONCOKBPATH";
    mvn -Dmaven.test.skip=true install -P public -q
    cp ~/"$ONCOKBPATH"/web/target/app.war ~/"$GDRP$FN"/beta.war
    echo "*************** Done ***************";
fi

# Create cbx war
if [[ $VERSIONS == *"cbx"* ]]
then
    echo "***************Building cbx OncoKB Instance***************";
    cd ~/"$ONCOKBPATH";
    git checkout $BRANCH;
    cp ~/"$GDProps"/dashi.cbx/database.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.cbx/config.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.cbx/log4j.properties ~/"$ONCOKB_CORE_RESOURCES_PATH"/
    cp ~/"$GDProps"/dashi.cbx/sentry.properties ~/"$ONCOKB_WEB_RESOURCES_PATH"/
    cd ~/"$ONCOKBPATH";
    mvn clean -P public -q
    cd ~/"$ONCOKBPATH";
    mvn -Dmaven.test.skip=true install -P public -q
    cp ~/"$ONCOKBPATH"/web/target/app.war ~/"$GDRP$FN"/cbx.war
    echo "*************** Done ***************";
fi

# Create curate war
if [[ $VERSIONS == *"curate"* ]]
then
    echo "***************Building Curate OncoKB Instance***************";
    cd ~/"$ONCOKBPATH";
    git checkout curate-release;
    cp ~/"$GDProps"/dashi.curate/database.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.curate/config.properties ~/"$ONCOKB_CORE_PROPERTY_PATH"/
    cp ~/"$GDProps"/dashi.curate/log4j.properties ~/"$ONCOKB_CORE_RESOURCES_PATH"/
    cp ~/"$GDProps"/dashi.curate/sentry.properties ~/"$ONCOKB_WEB_RESOURCES_PATH"/
    cd ~/"$ONCOKBPATH";
    mvn clean -P curate
    cd ~/"$ONCOKBPATH";
    mvn -Dmaven.test.skip=true install -P curate -q
    cp ~/"$ONCOKBPATH"/web/target/app.war ~/"$GDRP$FN"/curate.war
    echo "*************** Done ***************";
fi


# Switch back to master branch
cd ~/"$ONCOKBPATH";
git checkout $BRANCH;

# Remove all properties
rm -r ~/"$ONCOKB_CORE_PROPERTY_PATH"
rm -r ~/"$ONCOKB_CORE_RESOURCES_PATH"/log4j.properties
rm -r ~/"$ONCOKB_WEB_RESOURCES_PATH"

