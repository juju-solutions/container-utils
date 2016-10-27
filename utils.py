import os
import shutil

from subprocess import check_output

from charmhelpers.payload.archive import extract
from charmhelpers.core import hookenv


def arch():
    '''Return the package architecture as a string.'''
    # Get the package architecture for this system.
    architecture = check_output(['dpkg', '--print-architecture']).rstrip()
    # Convert the binary result into a string.
    architecture = architecture.decode('utf-8')
    return architecture


def get_resource(basename, expected_size=1000000):
    '''Return the named resource from Juju based on architecture, with a
    minimum expected size. Handle fetching errors, zero byte files and
    incomplete resources with the approprate status message.'''
    resource = None
    try:
        name = '{0}-{1}'.format(basename, arch())
        resource = hookenv.resource_get(name)
    except Exception as e:
        # Catch and log all exceptions, connection, and not implemented, etc.
        hookenv.log(e)
        error_message = 'Error fetching the {0} resource.'.format(name)
        hookenv.status_set('blocked', error_message)
        return resource
    # When the resource is empty string we have nothing to do.
    if not resource:
        zero_message = 'Missing {0} resource.'.format(name)
        hookenv.status_set('blocked', zero_message)
    else:
        # Check for incomplete resources when the function returned correctly.
        filesize = os.stat(resource).st_size
        if filesize < expected_size:
            incomplete_message = 'Incomplete {0} resource.'.format(name)
            hookenv.status_set('blocked', incomplete_message)
    return resource


def unpack_and_install(archive, files, destination='/usr/local/bin'):
    '''Untar the archive and copy the services to the destination directory.'''
    files_directory = os.path.join(hookenv.charm_dir(), 'files')
    hookenv.log('Extracting {0} to {1}'.format(archive, files_directory))
    # Extract the archive to the files directory.
    extract(archive, files_directory)
    # Copy each of the files to the destination directory.
    if files and isinstance(files, list):
        for file_name in files:
            source = os.path.join(files_directory, file_name)
            hookenv.log('Copying {0} to {1}'.format(source, destination))
            shutil.copy2(source, destination)


def is_dns_ready():
    '''Return True when the kube-dns is ready.'''
    # cluster-info or kubectl get -f kubedns.rc.yaml && kubectl get -f kubedns-svc.yaml
    pass


def create_kubeconfig():
    '''x'''
    pass
