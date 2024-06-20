#!/bin/bash

# After making changes to this file, please run
# airflow create cm airflow-volume-setup --from-file=scripts/setup_volume.sh
# to deploy the changes.

repo_dir="/opt/airflow/git_repos"

clone_repo() {
    repo_name="$1"
    repo_url="$2"

    # Check if repo already exists
    if [ -d "${repo_dir}/${repo_name}" ] ; then
        echo "${repo_name} already exists"
        return
    fi

    # Git clone
    echo "Cloning repo ${repo_url} to ${repo_dir}/${repo_name}"
    (   # Executed in a subshell to avoid changing the actual working directory
        # If any statement fails, the return value of the entire expression is the failure status
        cd $repo_dir &&
        git clone $repo_url
    )
    if [ $? -gt 0 ] ; then
	    echo "Error: Failed to clone $repo_url"
    fi	
}

clone_repos() {
    clone_repo nci-crdc-pipeline git@github.com:cBioPortal/nci-crdc-pipeline.git
    clone_repo genome-nexus-annotation-pipeline git@github.com:genome-nexus/genome-nexus-annotation-pipeline.git

    # CDM lines take a long time + are causing NCI pipeline to fail rn
    #clone_repo cmo-pipelines git@github.com:knowledgesystems/cmo-pipelines.git
    #clone_repo cdm-utilities_DEPRECATED git@github.com:clinical-data-mining/cdm-utilities_DEPRECATED.git
    #clone_repo cdm-cbioportal-etl git@github.com:clinical-data-mining/cdm-cbioportal-etl.git
}

clone_lfs_repo() {
    repo_name="$1"
    repo_url="$2"
    subdir="$3"

    # Check if repo already exists
    if [ -d "${repo_dir}/${repo_name}" ] ; then
        echo "${repo_name} already exists"
        return
    fi

    # Git clone
    echo "Cloning LFS repo ${repo_url} to ${repo_dir}/${repo_name}"
    (   # Executed in a subshell to avoid changing the actual working directory
        # If any statement fails, the return value of the entire expression is the failure status
        cd $repo_dir &&
        git clone $repo_url &&
        cd $repo_name &&
        # Install LFS hooks into repo
        git lfs install --local --skip-smudge &&
        # Download the data files for a study folder
        git lfs pull -I "${subdir}"
    )
    if [ $? -gt 0 ] ; then
        echo "Error: Failed to clone $repo_url"
    fi
}

clone_lfs_repos() {
    # Configure Git LFS not to download all data files right away
    git lfs install --skip-repo --skip-smudge
    
    clone_lfs_repo msk-impact git@github.mskcc.org:cdsi/msk-impact.git msk_solid_heme
    # TODO: smudge legacy TCGA studies so we can read survival data attributes from them. something like
    #clone_lfs_repo datahub git@github.com:cBioPortal/datahub.git public/**_gdc public/**_tcga public/**_tcga_pan_can_atlas_2018
    clone_lfs_repo datahub git@github.com:cBioPortal/datahub.git public/**_gdc
}

configure_git() {
    git config --global user.name "cbioportal import user"
    git config --global user.email "cbioportal_importer@pipelines.cbioportal.mskcc.org"
}

build_gnap() {
    repo_path="${repo_dir}/genome-nexus-annotation-pipeline"

    # Check if jar already exists
    # THIS DOES NOT WORK-- test -f will not do glob expansion. It'll check for a file with a literal * in its name.
    #if [ -f "${repo_path}/annotationPipeline/target/annotationPipeline-*.jar" ]; then
    # https://stackoverflow.com/a/34195247/4077294
    if compgen -G "${repo_path}/annotationPipeline/target/annotationPipeline-*.jar"; then
        echo "GNAP jar already exists"
        return
    fi

    # Maven complains about "detected dubious ownership of repository ..." if we don't add this line
    git config --global --add safe.directory "$repo_path"

    echo "Building GNAP"
    echo "JAVA_HOME: $JAVA_HOME"
    echo "Java version:" # should be 21
    java -version
    (   # Executed in a subshell to avoid changing the actual working directory
        # If any statement fails, the return value of the entire expression is the failure status
        cd $repo_path &&
        # Create properties files
        cp annotationPipeline/src/main/resources/application.properties.EXAMPLE annotationPipeline/src/main/resources/application.properties &&
        cp annotationPipeline/src/main/resources/log4j.properties.EXAMPLE annotationPipeline/src/main/resources/log4j.properties &&
        # Modify the property log4j.appender.a.File in your log4j.properties file to the desired log file path.
        sed -i "s#/path/to/logfile.log#/${repo_path}/logs/logfile.log#g" annotationPipeline/src/main/resources/log4j.properties &&
        # Build the annotator jar
        mvn clean install -DskipTests
    )
}

clone_repos
clone_lfs_repos
configure_git
build_gnap
