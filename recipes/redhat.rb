# Redhat (and related) specific code

include_recipe "yum::epel"

package "libicu-devel"
package "openssl-devel"
