FROM registry.fedoraproject.org/f27/s2i-base:latest
MAINTAINER ASI <asi@dbca.wa.gov.au>

EXPOSE 8080

ENV PYTHON_VERSION=3.6 \
    PATH=$HOME/.local/bin/:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off \
    NAME=python3 \
    VERSION=0 \
    RELEASE=1 \
    ARCH=x86_64 \
    SUMMARY="Platform for building and running Python $PYTHON_VERSION applications" \
    DESCRIPTION="Python $PYTHON_VERSION available as docker container is a base platform for \
building and running various Python $PYTHON_VERSION applications and frameworks. \
Includes an installed version of GDAL to allow spatial data processing."

LABEL summary="$SUMMARY" \
    description="$DESCRIPTION" \
    io.k8s.description="$DESCRIPTION" \
    io.k8s.display-name="Python 3.6" \
    io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,python,python36,rh-python36,gdal" \
    com.redhat.component="$NAME" \
    name="$FGC/$NAME" \
    version="$VERSION" \
    release="$RELEASE.$DISTTAG" \
    architecture="$ARCH" \
    usage="s2i build https://github.com/dbca-wa/s2i-django.git --context-dir=test/setup-test-app/ $FGC/$NAME python-sample-app"

RUN INSTALL_PKGS="python3 python3-devel python3-setuptools python3-pip python3-virtualenv \
    nss_wrapper httpd httpd-devel atlas-devel gcc-gfortran libffi-devel libtool-ltdl \
    enchant gdal gdal-devel rsync" && \
    dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    dnf clean all -y

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH.
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# - Create a Python virtual environment for use by any application to avoid
#   potential conflicts with Python packages preinstalled in the main Python
#   installation.
# - In order to drop the root user, we have to make some directories world
#   writable as OpenShift default security model is to run the container
#   under random UID.
RUN virtualenv-$PYTHON_VERSION ${APP_ROOT} && \
    chown -R 1001:0 ${APP_ROOT} && \
    fix-permissions ${APP_ROOT} -P

USER 1001

# Set the default CMD to print the usage of the language image.
CMD $STI_SCRIPTS_PATH/usage
