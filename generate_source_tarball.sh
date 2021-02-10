#!/bin/bash
# Generates the 'source tarball' for jdk8u projects.
#
# Example:
# When used from local repo set REPO_ROOT pointing to file:// with your repo
# If your local repo follows upstream forests conventions, it may be enough to set OPENJDK_URL
# If you want to use a local copy of patch PR3756, set the path to it in the PR3756 variable
#
# In any case you have to set PROJECT_NAME REPO_NAME and VERSION. eg:
# PROJECT_NAME=jdk8u   OR   aarch64-port 
# REPO_NAME=jdk8u60    OR   jdk8u60 
# VERSION=jdk8u60-b27  OR aarch64-jdk8u65-b17 OR for head, keyword 'tip' should do the job there
# 
# They are used to create correct name and are used in construction of sources url (unless REPO_ROOT is set)

# This script creates a single source tarball out of the repository
# based on the given tag and removes code not allowed in fedora/rhel. For
# consistency, the source tarball will always contain 'openjdk' as the top
# level folder, name is created, based on parameter
#

set -e

OPENJDK_URL_DEFAULT=http://hg.openjdk.java.net
COMPRESSION_DEFAULT=xz
# jdk is last for its size
REPOS_DEFAULT="hotspot corba jaxws jaxp langtools nashorn jdk"

if [ "x$1" = "xhelp" ] ; then
    echo -e "Behaviour may be specified by setting the following variables:\n"
    echo "VERSION - the version of the specified OpenJDK project"
    echo "PROJECT_NAME -- the name of the OpenJDK project being archived (optional; only needed by defaults)"
    echo "REPO_NAME - the name of the OpenJDK repository (optional; only needed by defaults)"
    echo "OPENJDK_URL - the URL to retrieve code from (optional; defaults to ${OPENJDK_URL_DEFAULT})"
    echo "COMPRESSION - the compression type to use (optional; defaults to ${COMPRESSION_DEFAULT})"
    echo "FILE_NAME_ROOT - name of the archive, minus extensions (optional; defaults to PROJECT_NAME-REPO_NAME-VERSION)"
    echo "REPO_ROOT - the location of the Mercurial repository to archive (optional; defaults to OPENJDK_URL/PROJECT_NAME/REPO_NAME)"
    echo "PR3756 - the path to the PR3756 patch to apply (optional; downloaded if unavailable)"
    echo "REPOS - specify the repositories to use (optional; defaults to ${REPOS_DEFAULT})"
    exit 1;
fi


if [ "x$VERSION" = "x" ] ; then
    echo "No VERSION specified"
    exit -2
fi
echo "Version: ${VERSION}"
    
# REPO_NAME is only needed when we default on REPO_ROOT and FILE_NAME_ROOT
if [ "x$FILE_NAME_ROOT" = "x" -o "x$REPO_ROOT" = "x" ] ; then
    if [ "x$PROJECT_NAME" = "x" ] ; then
	echo "No PROJECT_NAME specified"
	exit -1
    fi
    echo "Project name: ${PROJECT_NAME}"
    if [ "x$REPO_NAME" = "x" ] ; then
	echo "No REPO_NAME specified"
	exit -3
    fi
    echo "Repository name: ${REPO_NAME}"
fi

if [ "x$OPENJDK_URL" = "x" ] ; then
    OPENJDK_URL=${OPENJDK_URL_DEFAULT}
    echo "No OpenJDK URL specified; defaulting to ${OPENJDK_URL}"
else
    echo "OpenJDK URL: ${OPENJDK_URL}"
fi

if [ "x$COMPRESSION" = "x" ] ; then
# rhel 5 needs tar.gz
    COMPRESSION=${COMPRESSION_DEFAULT}
fi
echo "Creating a tar.${COMPRESSION} archive"

if [ "x$FILE_NAME_ROOT" = "x" ] ; then
    FILE_NAME_ROOT=${PROJECT_NAME}-${REPO_NAME}-${VERSION}
    echo "No file name root specified; default to ${FILE_NAME_ROOT}"
fi
if [ "x$REPO_ROOT" = "x" ] ; then
    REPO_ROOT="${OPENJDK_URL}/${PROJECT_NAME}/${REPO_NAME}"
    echo "No repository root specified; default to ${REPO_ROOT}"
fi;

mkdir "${FILE_NAME_ROOT}"
pushd "${FILE_NAME_ROOT}"

echo "Cloning ${VERSION} root repository from ${REPO_ROOT}"
hg clone ${REPO_ROOT} openjdk -r ${VERSION}
pushd openjdk
	

if [ "x$REPOS" = "x" ] ; then
    repos=${REPOS_DEFAULT}
    echo "No repositories specified; defaulting to ${repos}"
else
    repos=$REPOS
    echo "Repositories: ${repos}"
fi;

for subrepo in $repos
do
    echo "Cloning ${VERSION} ${subrepo} repository from ${REPO_ROOT}"
    hg clone ${REPO_ROOT}/${subrepo} -r ${VERSION}
done

popd
echo "Compressing remaining forest"
if [ "X$COMPRESSION" = "Xxz" ] ; then
    SWITCH=cJf
else
    SWITCH=czf
fi
TARBALL_NAME=${FILE_NAME_ROOT}.tar.${COMPRESSION}
tar --exclude-vcs -$SWITCH ${TARBALL_NAME} openjdk
mv ${TARBALL_NAME} ..

popd
echo "Done. You may want to remove the uncompressed version."
