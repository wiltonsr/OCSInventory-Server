################################################################################
## OCSINVENTORY-NG
## Copyleft Gilles DUBOIS 2015
## Web : http://www.ocsinventory-ng.org
##
## This code is open source and may be copied and modified as long as the source
## code is always made freely available.
## Please refer to the General Public Licence http://www.gnu.org/ or Licence.txt
################################################################################

package Apache::Ocsinventory::Plugins::Modules;

use SOAP::Lite;
use strict;
use LWP::Simple;
use Archive::Zip;
use File::Copy;
use File::Path;
use DBI;
  
sub InstallPlugins {

    my $pluginName = $_[1];

    # Download the created archive from the ocsreports which contain the communication server code (.conf and map.pm)
    my $url = "http://$ENV{OCS_DB_HOST}/ocsreports/upload/$pluginName.zip";
    my $file = "$ENV{OCS_PLUGINS_CONF_DIR}/$pluginName.zip";
    our $result;
    our $perm = 1;

    #Up case plugin directory in OCS server for match with actual template
    our $pluginNameUc = ucfirst($pluginName);

    if (-e "$ENV{OCS_PLUGINS_CONF_DIR}/$pluginName.conf") {
        $result = "Err_01";
    }
    elsif(-e "$ENV{OCS_PLUGINS_PERL_DIR}/Apache/Ocsinventory/Plugins/$pluginNameUc"){
        $result = "Err_05";
    }
    else
    {

        my $status = getstore($url, $file);

        # If download succes, unzip, create dir, move files.
        if (is_success($status))
        {

            # Check for write perm in plugins dir
            if(!(-w "$ENV{OCS_PLUGINS_CONF_DIR}"))
            {
                $result = "Err_03";
                $perm = 0;
            }
            # Check for write perm in perl dir
            if(!(-w "$ENV{OCS_PLUGINS_PERL_DIR}/Apache/Ocsinventory/Plugins"))
            {
                $result = "Err_04";
                $perm = 0;
            }

            if($perm){
                my $pluginsdir = "$ENV{OCS_PLUGINS_CONF_DIR}";
                my $zipname = $file;
                my $destinationDirectory = $pluginsdir;
                my $zip = Archive::Zip->new($zipname);
                my $member;

                foreach my $member ($zip->members)
                {
                        next if $member->isDirectory;
                        (my $extractName = $member->fileName) =~ s{.*/}{};
                        $member->extractToFileNamed("$destinationDirectory/$extractName");
                }

                my $dirtocreate = "$ENV{OCS_PLUGINS_PERL_DIR}/Apache/Ocsinventory/Plugins/$pluginNameUc";
                mkdir $dirtocreate;

                unlink $file;
                move("$pluginsdir/Map.pm","$ENV{OCS_PLUGINS_PERL_DIR}/Apache/Ocsinventory/Plugins/$pluginNameUc/Map.pm");

                $result = "Install_OK";
            }

        }else{
            $result = "Err_02";
        }

    }

    return( SOAP::Data->name( 'Result' => $result )->type( 'string' ) );

}

# Seek for deleted plugins // Delete map.pm and conf entry.
sub DeletePlugins {
	
    my $pluginName = $_[1];

    #Up case plugin directory in OCS server for match with actual template for deletion
    my $pluginNameUc = ucfirst($pluginName);

    my $pluginsdir = "$ENV{OCS_PLUGINS_CONF_DIR}";

    if (-e "$ENV{OCS_PLUGINS_CONF_DIR}/$pluginName.conf"){
            unlink "$ENV{OCS_PLUGINS_CONF_DIR}/$pluginName.conf";
    }

    rmtree "$ENV{OCS_PLUGINS_PERL_DIR}/Apache/Ocsinventory/Plugins/$pluginNameUc";

    my $result = "Delete_OK";

    return( SOAP::Data->name( 'Result' => $result )->type( 'string' ) );
}

1;